FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Collect static files at build time (dummy key — collectstatic doesn't need the real one)
RUN SECRET_KEY=dummy-build-key python manage.py collectstatic --noinput

EXPOSE 8000

# At startup: run migrations, seed admin, seed exercises, then serve
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py create_admin && python manage.py seed_exercises && gunicorn fitquest_backend.wsgi --bind 0.0.0.0:8000 --workers 2"]
