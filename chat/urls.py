from django.urls import path
from .views import (
    DMConversationView, CommunityFeedView, SendMessageView, MarkReadView,
    GroupListView, CreateGroupView, GroupConversationView,
)

urlpatterns = [
    path('dm/<int:athlete_id>/', DMConversationView.as_view(),      name='dm-conversation'),
    path('community/',           CommunityFeedView.as_view(),        name='community-feed'),
    path('send/',                SendMessageView.as_view(),           name='send-message'),
    path('read/<int:pk>/',       MarkReadView.as_view(),              name='mark-read'),
    # Group chats
    path('groups/',              GroupListView.as_view(),             name='group-list'),
    path('groups/create/',       CreateGroupView.as_view(),           name='create-group'),
    path('group/<int:group_id>/', GroupConversationView.as_view(),   name='group-conversation'),
]
