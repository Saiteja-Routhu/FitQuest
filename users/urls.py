from django.urls import path
from .views import (
    RegisterView, LoginView, GenerateCoachKeyView, UserListView,
    CoachRosterView, AssignCoachView, AcknowledgeRecruitView, CoachSummaryView,
    AthleteAnalyticsView, LeaderboardView, MyCoachView, AssessmentCreateView,
    UpdateProfileView, SuperCoachRosterView, SuperCoachAthleteListView, DeleteUserView,
    SCAllAthletesView, SCAllCoachesView, SCClaimCoachView, SCClaimAthleteView,
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
    path('coach-summary/', CoachSummaryView.as_view(), name='coach-summary'),
    path('athletes/<int:recruit_id>/analytics/', AthleteAnalyticsView.as_view(), name='athlete-analytics'),

    # Shared (Coach + Recruit)
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),
    path('my-coach/', MyCoachView.as_view(), name='my-coach'),

    # Recruit: Post-registration assessment
    path('assessment/', AssessmentCreateView.as_view(), name='assessment'),

    # Phase 4: Profile + Super Coach + Admin
    path('profile/', UpdateProfileView.as_view(), name='update-profile'),
    path('my-coaches/', SuperCoachRosterView.as_view(), name='super-coach-roster'),
    path('coach/<int:coach_id>/athletes/', SuperCoachAthleteListView.as_view(), name='coach-athletes'),
    path('<int:user_id>/delete/', DeleteUserView.as_view(), name='delete-user'),

    # Phase 7: Super Coach "All" endpoints
    path('sc-all-athletes/', SCAllAthletesView.as_view(), name='sc-all-athletes'),
    path('sc-all-coaches/', SCAllCoachesView.as_view(), name='sc-all-coaches'),
    path('sc-claim-coach/<int:coach_id>/', SCClaimCoachView.as_view(), name='sc-claim-coach'),
    path('sc-claim-athlete/<int:athlete_id>/', SCClaimAthleteView.as_view(), name='sc-claim-athlete'),
]