package com.example.mongo_spring.config;

import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.core.MongoTemplate;

@Configuration
public class MongoConfig {
    DotenvConfig dotenvConfig = new DotenvConfig();

    private String getDatabaseName() {
        return this.dotenvConfig.dotenv().get("DB_NAME");
    }

    private String getPort() {
        return this.dotenvConfig.dotenv().get("DB_PORT");
    }

    private String getUsername() {
        return this.dotenvConfig.dotenv().get("DB_USERNAME");
    }

    private String getPassword() {
        return this.dotenvConfig.dotenv().get("DB_PASS");
    }

    @Bean
    public MongoClient mongoClient() {
        return MongoClients.create("mongodb://admin:"
                + getPassword() + "@localhost:"
                + this.getPort() + "/"
                + this.getDatabaseName()
                + "?authSource=" + this.getUsername());
    }

    @Bean
    public MongoTemplate mongoTemplate() {
        return new MongoTemplate(this.mongoClient(), this.getDatabaseName());
    }
}
