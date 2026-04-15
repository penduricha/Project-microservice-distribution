from pyspark.sql import SparkSession
from pyspark.ml import Pipeline
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.feature import VectorAssembler, StringIndexer
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.mllib.evaluation import MulticlassMetrics
from pyspark.sql.functions import col
from pymongo import MongoClient
from datetime import datetime

# 1. Initialize SparkSession optimized for 16GB RAM.
# username = "admin"
# password = "123"
# port = 27018
# mongo_uri = f"mongodb://{username}:{password}@127.0.0.1:{port}/admin?authSource=admin"

spark = (SparkSession.builder
    .appName("Optimized_RF_50M_Rows")
    # Allocate 12GB for drivers, leaving 4GB for the OS and Docker overhead.
    .config("spark.driver.memory", "12g")
    .config("spark.executor.memory", "12g")
    
    # Memory Optimization: Allocate 80% of RAM to Spark,
    # Prioritizing Execution (RF computation) over Storage (cache)
    .config("spark.memory.fraction", "0.8")
    .config("spark.memory.storageFraction", "0.2")
    
    # Data partitioning: 50 million rows should be divided into at least 500 partitions.
    .config("spark.sql.shuffle.partitions", "500")
    .config("spark.default.parallelism", "500")
    
    # Avoid timeouts when processing large volumes.
    .config("spark.network.timeout", "1200s")
    .config("spark.sql.broadcastTimeout", "1200s")
    
    # Config MongoDB Connector
    # .config("spark.mongodb.write.connection.uri", mongo_uri)
    # .config("spark.jars.packages", "org.mongodb.spark:mongo-spark-connector_2.12:10.2.2")
    .getOrCreate())

# Thiết lập thư mục Checkpoint trên HDFS để giải phóng RAM trong quá trình train
# ip can change
ip_namenode = '172.20.0.4'
spark.sparkContext.setCheckpointDir(f"hdfs://{ip_namenode}:9000/user/checkpoints")

# 2. Data collection from HDFS
hdfs_path = f"hdfs://{ip_namenode}:9000/user/data/drug200.csv"

# Read data parallel
df = spark.read.csv(hdfs_path, header=True, inferSchema=True)

# 3.Feature Engineering
# Indexing cho Label
labelIndexer = StringIndexer(inputCol="Drug", outputCol="indexedLabel", handleInvalid="skip")

# Indexing to classification fields
sexIndexer = StringIndexer(inputCol="Sex", outputCol="Sex_Index")
bpIndexer = StringIndexer(inputCol="BP", outputCol="BP_Index")
cholIndexer = StringIndexer(inputCol="Cholesterol", outputCol="Cholesterol_Index")

# gom các đặc trưng vào một vector
featureCols = ["Age", "Sex_Index", "BP_Index", "Cholesterol_Index", "Na_to_K"]
assembler = VectorAssembler(inputCols=featureCols, outputCol="features")

# 4. Train random forest that save RAM.
rf = RandomForestClassifier(
    labelCol="indexedLabel", 
    featuresCol="features", 
    numTrees=20,           # Giảm số cây (mỗi cây chiếm RAM khi build)
    maxDepth=5,            # Độ sâu thấp giúp giảm kích thước bộ nhớ node
    maxBins=16,            # Giảm số lượng bin để giảm dữ liệu thống kê trong RAM
    subsamplingRate=0.6,   # Mỗi cây chỉ lấy 60% dữ liệu để huấn luyện
    checkpointInterval=5   # Cứ 5 cây thì lưu checkpoint xuống HDFS một lần
)

# Tạo Pipeline
pipeline = Pipeline(stages=[labelIndexer, sexIndexer, bpIndexer, cholIndexer, assembler, rf])

# Chia dữ liệu Train/Test
(trainingData, testData) = df.randomSplit([0.8, 0.2], seed=42)

print("Đang bắt đầu quá trình huấn luyện mô hình...")
# Huấn luyện
model = pipeline.fit(trainingData)
print("Huấn luyện hoàn tất!")

# 5. Evaluate
predictions = model.transform(testData)

# evaluator = MulticlassClassificationEvaluator(
#     labelCol="indexedLabel", 
#     predictionCol="prediction", 
#     metricName="accuracy"
# )

# accuracy = evaluator.evaluate(predictions)
# print(f"Độ chính xác (Accuracy): {accuracy:.4f}")

# Tính toán Confusion Matrix bằng RDD API
predictionAndLabels = predictions.select("prediction", "indexedLabel") \
                                 .rdd.map(lambda row: (float(row.prediction), float(row.indexedLabel)))

# Khởi tạo evaluator
evaluator = MulticlassClassificationEvaluator(labelCol="indexedLabel", predictionCol="prediction")

# Tính Accuracy
accuracy = evaluator.evaluate(predictions, {evaluator.metricName: "accuracy"})

# Tính F1-Score (Trong Spark f1 chính là weighted F1)
f1 = evaluator.evaluate(predictions, {evaluator.metricName: "f1"})

# Tính Weighted Precision
weighted_precision = evaluator.evaluate(predictions, {evaluator.metricName: "weightedPrecision"})

# Tính Weighted Recall
weighted_recall = evaluator.evaluate(predictions, {evaluator.metricName: "weightedRecall"})

print(f"Accuracy: {accuracy:.4f}")
print(f"F1-Score: {f1:.4f}")
print(f"Precision: {weighted_precision:.4f}")
print(f"Recall: {weighted_recall:.4f}")

metrics = MulticlassMetrics(predictionAndLabels)
print("Ma trận nhầm lẫn (Confusion Matrix):")
print(metrics.confusionMatrix().toArray())

# # 6. Lưu kết quả dự đoán vào MongoDB
# print("Save to MongoDB...")

# # Thiết lập kết nối
# client = MongoClient(mongo_uri)
# db = client.admin

# db.predictions.delete_many({})

# def save_to_mongodb_partition(partition):
#     from pymongo import MongoClient
#     client = MongoClient(mongo_uri)
#     db = client.admin
#     collection = db.predictions
    
#     batch = []
#     for row in partition:
#         batch.append(row.asDict())
#         if len(batch) >= 5000: 
#             collection.insert_many(batch)
#             batch = []
#     if batch:
#         collection.insert_many(batch)
#     client.close()

# # Choose column to save
# predictions.select("Age", "Sex", "BP", "Cholesterol", "prediction") \
#     .foreachPartition(save_to_mongodb_partition)

# # prepare data report
# confusion_matrix_list = metrics.confusionMatrix().toArray().tolist() 
# # Numpy array to List

# report_data = {
#     "model_name": "Random Forest",
#     "timestamp": datetime.now(), 
#     "metrics": {
#         "accuracy": accuracy,
#         "f1_score": f1,
#         "precision": weighted_precision,
#         "recall": weighted_recall
#     },
#     "confusion_matrix": confusion_matrix_list
# }

# # Save to mongo
# report_collection = db.random_forest_report
# # Delete old data
# report_collection.delete_many({}) 
# report_collection.insert_one(report_data)

# print("Hoàn tất lưu dữ liệu!")
# print("End.")
spark.stop()