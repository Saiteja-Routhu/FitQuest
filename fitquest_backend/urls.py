from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Connect our apps here:
    path('api/users/', include('users.urls')),
    
    # We will uncomment these later as we build them:
     path('api/exercises/', include('exercises.urls')),
     path('api/workouts/', include('workouts.urls')),
     path('api/analytics/', include('analytics.urls')),
     path('api/nutrition/', include('nutrition.urls')),
     path('api/ai/', include('ai_services.urls')),
]