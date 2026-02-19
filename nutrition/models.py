from django.db import models
from users.models import CustomUser


# 1. THE PANTRY (Coach's Custom Food Library)
class FoodItem(models.Model):
    coach = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='food_items')
    name = models.CharField(max_length=100)
    serving_unit = models.CharField(max_length=20, default="100g")

    calories = models.FloatField(default=0)
    protein = models.FloatField(default=0)
    carbs = models.FloatField(default=0)
    fats = models.FloatField(default=0)

    def __str__(self):
        return f"{self.name} ({self.coach.username})"


# 2. THE DIET PLAN
class DietPlan(models.Model):
    coach = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='diet_plans')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    water_target_liters = models.FloatField(default=3.0)
    created_at = models.DateTimeField(auto_now_add=True)

    total_calories = models.FloatField(default=0)
    total_protein = models.FloatField(default=0)
    total_carbs = models.FloatField(default=0)
    total_fats = models.FloatField(default=0)

    assigned_to = models.ManyToManyField(CustomUser, related_name='assigned_diet_plans', blank=True)

    def __str__(self):
        return self.name


# 3. MEALS
class Meal(models.Model):
    MEAL_TYPES = [
        ('Breakfast', 'Breakfast'),
        ('Lunch', 'Lunch'),
        ('Snack', 'Snack'),
        ('Dinner', 'Dinner'),
        ('Pre-Workout', 'Pre-Workout'),
        ('Post-Workout', 'Post-Workout'),
    ]
    plan = models.ForeignKey(DietPlan, on_delete=models.CASCADE, related_name='meals')
    name = models.CharField(max_length=50, choices=MEAL_TYPES)
    order = models.IntegerField(default=1)

    def __str__(self):
        return f"{self.name} in {self.plan.name}"


# 4. MEAL ITEMS
class MealItem(models.Model):
    meal = models.ForeignKey(Meal, on_delete=models.CASCADE, related_name='items')
    food_item = models.ForeignKey(FoodItem, on_delete=models.CASCADE)
    quantity = models.FloatField(default=1.0)  # Multiplier

    def __str__(self):
        return f"{self.quantity}x {self.food_item.name}"


# 5. SUPPLEMENTS
class Supplement(models.Model):
    plan = models.ForeignKey(DietPlan, on_delete=models.CASCADE, related_name='supplements')
    name = models.CharField(max_length=100)
    dosage = models.CharField(max_length=100)
    notes = models.TextField(blank=True)

    def __str__(self):
        return self.name


# 6. WEEKLY SCHEDULE (NEW)
class DietSchedule(models.Model):
    DAYS = [
        ('Monday', 'Monday'), ('Tuesday', 'Tuesday'), ('Wednesday', 'Wednesday'),
        ('Thursday', 'Thursday'), ('Friday', 'Friday'), ('Saturday', 'Saturday'), ('Sunday', 'Sunday')
    ]
    coach = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='coach_schedules')
    recruit = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='diet_schedule')
    day_of_week = models.CharField(max_length=15, choices=DAYS)
    diet_plan = models.ForeignKey(DietPlan, on_delete=models.SET_NULL, null=True)

    class Meta:
        unique_together = ('recruit', 'day_of_week')

    def __str__(self):
        return f"{self.recruit.username} - {self.day_of_week}"