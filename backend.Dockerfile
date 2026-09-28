# CertusBI 后端镜像
FROM python:3.12-slim

WORKDIR /app

# 统一 UTF-8 输出，避免脚本/日志在不同 locale 下的编码问题
ENV PYTHONIOENCODING=utf-8

# 先装依赖（利用 Docker 层缓存）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip install --no-cache-dir jieba "pymilvus[milvus_lite]" \
    -i https://pypi.tuna.tsinghua.edu.cn/simple

# 拷贝业务代码
COPY backend/ ./backend/
COPY cli.py ./
# 拷贝数据集生成脚本（纯标准库、固定 seed，可复现）
COPY scripts/gen_olist_db.py scripts/gen_ecommerce_db.py ./scripts/
# 构建时生成 SQLite 数据集，无需提前准备 data/ 目录
RUN python scripts/gen_olist_db.py \
    && python scripts/gen_ecommerce_db.py
# 拷贝知识库文档（schema 文档等）
COPY docs/ ./docs/

# 容器内访问同一 compose 网络的兄弟容器
ENV PYTHONPATH=/app/backend

EXPOSE 8000

WORKDIR /app/backend

CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
