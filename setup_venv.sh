#!/bin/bash
rm -rf .venv
# Lay duong dan hien tai
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "[1/3] Creating .venv-"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "Created .venv."
else
    echo ".venv existed"
fi

echo "Setting library"
# Kich hoat moi truong ao
source .venv/bin/activate

# Cap nhat pip va cai dat package
pip install --upgrade pip
pip install pyspark numpy pandas findspark joblib scikit-learn ipykernel xgboost redis seaborn matplotlib 

# Xuat file requirements
pip freeze > requirements.txt

# Thoat khoi venv
deactivate

echo "Done"
echo "De kich hoat lai, su dung: source .venv/bin/activate"