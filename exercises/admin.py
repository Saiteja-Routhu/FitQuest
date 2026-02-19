from django.contrib import admin
from .models import Exercise

@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):
    list_display = ('name', 'muscle_group', 'difficulty', 'equipment')
    list_filter = ('muscle_group', 'difficulty', 'equipment')
    search_fields = ('name',)