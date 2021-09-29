from locust import HttpUser, task

class WebUser(HttpUser):
  @task
  def index(self):
    self.client.get("/")
