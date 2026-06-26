FROM python:3.14-slim

WORKDIR /app
COPY requirements.txt .
RUN pip3 install -r requirements.txt
COPY . .

EXPOSE 8080
# TODO: Use Gunicorn/WSGI alternative --- decision to be made when we decide which tech stack to support
CMD [ "python3", "-m", "flask", "--app=main", "run", "--host=0.0.0.0","--port=8080" ]
