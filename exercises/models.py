from django.db import models


class Exercise(models.Model):
    # Categories
    MUSCLE_GROUP_CHOICES = [
        ('chest', 'Chest'),
        ('back', 'Back'),
        ('legs', 'Legs'),
        ('shoulders', 'Shoulders'),
        ('arms', 'Arms'),
        ('core', 'Core'),
        ('cardio', 'Cardio'),
        ('full_body', 'Full Body'),
    ]

    EQUIPMENT_CHOICES = [
        ('none', 'Bodyweight'),
        ('dumbbell', 'Dumbbell'),
        ('barbell', 'Barbell'),
        ('kettlebell', 'Kettlebell'),
        ('machine', 'Machine'),
        ('cables', 'Cables'),
    ]

    DIFFICULTY_CHOICES = [
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('expert', 'Expert'),
    ]

    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    muscle_group = models.CharField(max_length=20, choices=MUSCLE_GROUP_CHOICES)
    equipment = models.CharField(max_length=20, choices=EQUIPMENT_CHOICES, default='none')
    difficulty = models.CharField(max_length=20, choices=DIFFICULTY_CHOICES, default='beginner')

    # Media (Optional but good for demo)
    image_url = models.URLField(blank=True, null=True, help_text="Link to an image of the exercise")
    video_url = models.URLField(blank=True, null=True, help_text="YouTube link for demonstration")

    def __str__(self):
        return self.name