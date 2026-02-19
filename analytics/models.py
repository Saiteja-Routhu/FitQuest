from django.db import models
from django.conf import settings  # ✅ FIXED IMPORT

class WorkoutLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE) # ✅ FIXED RELATION
    duration_minutes = models.IntegerField()
    calories_burned = models.FloatField()
    workout_type = models.CharField(max_length=100)
    date = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.workout_type} ({self.date.date()})"