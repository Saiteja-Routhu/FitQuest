from django.urls import path
from . import views

urlpatterns = [
    path('',                   views.CoachQuestListView.as_view(),     name='coach-quests'),
    path('create/',            views.CreateQuestView.as_view(),        name='create-quest'),
    path('assign/',            views.AssignQuestView.as_view(),        name='assign-quest'),
    path('my-quests/',         views.MyQuestsView.as_view(),           name='my-quests'),
    path('complete/',          views.CompleteQuestView.as_view(),      name='complete-quest'),
    path('today/',             views.TodayQuestsView.as_view(),        name='today-quests'),
    path('today/complete/',    views.CompleteDailyQuestView.as_view(), name='complete-daily-quest'),
    path('<int:pk>/',          views.DeleteQuestView.as_view(),        name='delete-quest'),
]
