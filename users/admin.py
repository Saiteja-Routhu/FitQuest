from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, CoachAccessKey

class CustomUserAdmin(UserAdmin):
    # Add our new fields to the Admin UI
    fieldsets = UserAdmin.fieldsets + (
        ('Role & Stats', {'fields': ('role', 'height', 'weight', 'activity_level', 'goal')}),
        ('Game Stats', {'fields': ('level', 'xp', 'coins')}),
    )
    list_display = ['username', 'email', 'role', 'level', 'coins']
    list_filter = ['role', 'level']

class CoachKeyAdmin(admin.ModelAdmin):
    list_display = ['key', 'is_used', 'created_at']
    list_filter = ['is_used']

admin.site.register(CustomUser, CustomUserAdmin)
admin.site.register(CoachAccessKey, CoachKeyAdmin)