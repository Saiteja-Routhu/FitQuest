from django.urls import path
from .views import (
    RegisterView, LoginView, GenerateCoachKeyView, UserListView,
    CoachRosterView, AssignCoachView, AcknowledgeRecruitView  # 👈 I ADDED THIS!
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('generate-key/', GenerateCoachKeyView.as_view(), name='generate-key'),
    path('all/', UserListView.as_view(), name='user-list'),

    # Coach URLs
    path('my-roster/', CoachRosterView.as_view(), name='coach-roster'),
    path('assign-coach/', AssignCoachView.as_view(), name='assign-coach'),
    path('acknowledge-recruit/', AcknowledgeRecruitView.as_view(), name='acknowledge'),
]