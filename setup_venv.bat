@echo off
:: Di chuyển đến thư mục chứa script
cd /d "%~dp0"

echo [1/3] Kiem tra va tao moi truong ao .venv...
if not exist ".venv" (
    python -m venv .venv
    echo Da tao xong .venv.
) else (
    echo .venv da ton tai.
)

echo [2/3] Kich hoat .venv va cai dat thu vien...
:: Su dung cmd /c de chay cac lenh ben trong moi truong ao
call .\.venv\Scripts\activate && (
    python -m pip install --upgrade pip
    pip install pyspark numpy pandas findspark joblib scikit-learn ipykernel xgboost
    echo Xuat file requirements.txt...
    pip freeze > requirements.txt
    deactivate
)

echo [3/3] Hoan tat! 
echo De kich hoat manually, dung lenh: .\.venv\Scripts\activate
pause