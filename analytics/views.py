import re
from datetime import date, timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import WorkoutLog, DailyActivity, BodyProgressEntry, UserActivityStatus, WorkoutSetLog
from .serializers import WorkoutLogSerializer
from users.models import CustomUser


class WorkoutLogViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WorkoutLog.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# ── Daily Activity (water + steps) ───────────────────────────────────────────
class DailyActivityView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _get_today(self, user):
        activity, _ = DailyActivity.objects.get_or_create(
            user=user, date=date.today())
        return activity

    def get(self, request):
        a = self._get_today(request.user)
        return Response({
            'id': a.id,
            'date': str(a.date),
            'water_ml': a.water_ml,
            'water_goal_ml': a.water_goal_ml,
            'steps': a.steps,
            'step_goal': a.step_goal,
        })

    def post(self, request):
        a, _ = DailyActivity.objects.get_or_create(
            user=request.user, date=date.today())
        if 'water_ml' in request.data:
            a.water_ml = int(request.data['water_ml'])
        if 'water_goal_ml' in request.data:
            a.water_goal_ml = int(request.data['water_goal_ml'])
        if 'steps' in request.data:
            a.steps = int(request.data['steps'])
        if 'step_goal' in request.data:
            a.step_goal = int(request.data['step_goal'])
        a.save()
        return Response({
            'id': a.id,
            'date': str(a.date),
            'water_ml': a.water_ml,
            'water_goal_ml': a.water_goal_ml,
            'steps': a.steps,
            'step_goal': a.step_goal,
        })


# ── Body Progress ─────────────────────────────────────────────────────────────
class BodyProgressListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _entry_dict(self, e, request):
        d = {
            'id': e.id,
            'date': str(e.date),
            'weight_kg': e.weight_kg,
            'waist_cm': e.waist_cm,
            'chest_cm': e.chest_cm,
            'arms_cm': e.arms_cm,
            'thighs_cm': e.thighs_cm,
            'ai_analysis': e.ai_analysis,
            'body_fat_estimate': e.body_fat_estimate,
        }
        base = request.build_absolute_uri('/')[:-1]
        if e.photo_front:
            d['photo_front_url'] = base + e.photo_front.url
        if e.photo_side:
            d['photo_side_url'] = base + e.photo_side.url
        if e.photo_back:
            d['photo_back_url'] = base + e.photo_back.url
        return d

    def get(self, request):
        entries = BodyProgressEntry.objects.filter(
            user=request.user).order_by('-date')
        return Response([self._entry_dict(e, request) for e in entries])

    def post(self, request):
        weight = request.data.get('weight_kg')
        waist = request.data.get('waist_cm')
        chest = request.data.get('chest_cm')
        arms = request.data.get('arms_cm')
        thighs = request.data.get('thighs_cm')
        manual_body_fat = request.data.get('manual_body_fat')

        # Handle file uploads
        photo_front_file = request.FILES.get('photo_front')
        photo_side_file = request.FILES.get('photo_side')
        photo_back_file = request.FILES.get('photo_back')

        # Legacy b64 support
        photo_front_b64 = request.data.get('photo_front_b64', '')
        photo_side_b64 = request.data.get('photo_side_b64', '')
        photo_back_b64 = request.data.get('photo_back_b64', '')

        ai_analysis = ''
        body_fat_estimate = None

        # Call Gemini if photos provided and API key is set
        api_key = getattr(settings, 'GEMINI_API_KEY', '')
        has_photos = photo_front_file or photo_front_b64

        if api_key and api_key != 'your-gemini-api-key-here' and has_photos:
            try:
                import google.generativeai as genai
                import base64

                genai.configure(api_key=api_key)
                model = genai.GenerativeModel('gemini-1.5-flash')

                prompt_text = (
                    f"You are a professional fitness coach. Analyze these front/side/back "
                    f"physique photos combined with these measurements: "
                    f"weight={weight}kg, waist={waist}cm, chest={chest}cm, "
                    f"arms={arms}cm, thighs={thighs}cm. "
                    f"Provide: 1) Estimated body fat % range 2) Current physique observations "
                    f"3) Key areas needing improvement 4) Positive changes noted. "
                    f"Be encouraging and professional."
                )

                content_parts = [prompt_text]

                # Handle file uploads (multipart)
                for photo_file in [photo_front_file, photo_side_file, photo_back_file]:
                    if photo_file:
                        photo_bytes = photo_file.read()
                        photo_file.seek(0)  # Reset for later save
                        content_parts.append(
                            genai.Part.from_data(
                                data=photo_bytes,
                                mime_type='image/jpeg'
                            )
                        )

                # Handle b64 fallback
                if not photo_front_file:
                    for b64_str in [photo_front_b64, photo_side_b64, photo_back_b64]:
                        if b64_str:
                            try:
                                photo_bytes = base64.b64decode(b64_str)
                                content_parts.append(
                                    genai.Part.from_data(
                                        data=photo_bytes,
                                        mime_type='image/jpeg'
                                    )
                                )
                            except Exception:
                                pass

                response = model.generate_content(content_parts)
                ai_analysis = response.text

                # Parse body fat % from analysis text
                match = re.search(r'(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)\s*%', ai_analysis)
                if match:
                    low = float(match.group(1))
                    high = float(match.group(2))
                    body_fat_estimate = (low + high) / 2
                else:
                    match = re.search(r'(\d+(?:\.\d+)?)\s*%', ai_analysis)
                    if match:
                        body_fat_estimate = float(match.group(1))
            except Exception as e:
                ai_analysis = ''
                # Don't block save on AI failure

        # Use manual body fat if AI failed and manual provided
        if body_fat_estimate is None and manual_body_fat is not None:
            try:
                body_fat_estimate = float(manual_body_fat)
            except (ValueError, TypeError):
                pass

        entry = BodyProgressEntry.objects.create(
            user=request.user,
            weight_kg=weight,
            waist_cm=waist,
            chest_cm=chest,
            arms_cm=arms,
            thighs_cm=thighs,
            photo_front_b64=photo_front_b64,
            photo_side_b64=photo_side_b64,
            photo_back_b64=photo_back_b64,
            ai_analysis=ai_analysis,
            body_fat_estimate=body_fat_estimate,
        )

        # Save file uploads
        if photo_front_file:
            entry.photo_front.save(f'front_{entry.id}.jpg', photo_front_file, save=False)
        if photo_side_file:
            entry.photo_side.save(f'side_{entry.id}.jpg', photo_side_file, save=False)
        if photo_back_file:
            entry.photo_back.save(f'back_{entry.id}.jpg', photo_back_file, save=False)
        if photo_front_file or photo_side_file or photo_back_file:
            entry.save()

        base = request.build_absolute_uri('/')[:-1]
        resp = {
            'id': entry.id,
            'date': str(entry.date),
            'ai_analysis': entry.ai_analysis,
            'body_fat_estimate': entry.body_fat_estimate,
        }
        if entry.photo_front:
            resp['photo_front_url'] = base + entry.photo_front.url
        if entry.photo_side:
            resp['photo_side_url'] = base + entry.photo_side.url
        if entry.photo_back:
            resp['photo_back_url'] = base + entry.photo_back.url
        return Response(resp, status=status.HTTP_201_CREATED)


class BodyProgressDeleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, pk):
        try:
            entry = BodyProgressEntry.objects.get(id=pk, user=request.user)
            entry.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except BodyProgressEntry.DoesNotExist:
            return Response({'error': 'Not found'}, status=404)


# ── Photo Gallery ─────────────────────────────────────────────────────────────
class PhotoGalleryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        entries = BodyProgressEntry.objects.filter(
            user=request.user
        ).exclude(
            photo_front='', photo_side='', photo_back=''
        ).order_by('-date')

        base = request.build_absolute_uri('/')[:-1]
        result = {}
        for e in entries:
            date_str = str(e.date)
            if date_str not in result:
                result[date_str] = []
            photos = []
            if e.photo_front:
                photos.append({'type': 'front', 'url': base + e.photo_front.url})
            if e.photo_side:
                photos.append({'type': 'side', 'url': base + e.photo_side.url})
            if e.photo_back:
                photos.append({'type': 'back', 'url': base + e.photo_back.url})
            if photos:
                result[date_str].append({'entry_id': e.id, 'photos': photos})

        grouped = [{'date': d, 'entries': v} for d, v in sorted(result.items(), reverse=True)]
        return Response(grouped)


# ── Athlete Body Progress (Coach/SC view) ────────────────────────────────────
class AthleteBodyProgressView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, athlete_id):
        viewer = request.user
        try:
            athlete = CustomUser.objects.get(id=athlete_id, role='RECRUIT')
        except CustomUser.DoesNotExist:
            return Response({'error': 'Athlete not found'}, status=404)

        # Coach sees own athletes; SC sees athletes of managed coaches OR directly claimed athletes
        is_coach = viewer.role == 'GUILD_MASTER' and athlete.coach == viewer
        is_sc_direct = viewer.role == 'SUPER_COACH' and athlete.coach == viewer
        is_sc_managed = viewer.role == 'SUPER_COACH' and athlete.coach and athlete.coach.super_coach == viewer
        if not (is_coach or is_sc_direct or is_sc_managed):
            return Response({'error': 'Forbidden'}, status=403)

        entries = BodyProgressEntry.objects.filter(user=athlete).order_by('-date')
        base = request.build_absolute_uri('/')[:-1]
        data = []
        for e in entries:
            d = {
                'id': e.id,
                'date': str(e.date),
                'weight_kg': e.weight_kg,
                'waist_cm': e.waist_cm,
                'chest_cm': e.chest_cm,
                'arms_cm': e.arms_cm,
                'thighs_cm': e.thighs_cm,
                'ai_analysis': e.ai_analysis,
                'body_fat_estimate': e.body_fat_estimate,
            }
            if e.photo_front:
                d['photo_front_url'] = base + e.photo_front.url
            if e.photo_side:
                d['photo_side_url'] = base + e.photo_side.url
            if e.photo_back:
                d['photo_back_url'] = base + e.photo_back.url
            data.append(d)
        return Response(data)


# ── Live Activity Heartbeat ───────────────────────────────────────────────────
class HeartbeatView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        activity_type = request.data.get('activity_type', 'idle')
        steps_live = request.data.get('steps_live', 0)

        status_obj, _ = UserActivityStatus.objects.get_or_create(user=request.user)
        status_obj.last_heartbeat = timezone.now()
        status_obj.activity_type = activity_type
        status_obj.steps_live = int(steps_live)
        status_obj.save()

        return Response({'ok': True})


# ── Team Activity (Coach/SC view) ─────────────────────────────────────────────
class TeamActivityView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        viewer = request.user
        two_minutes_ago = timezone.now() - timedelta(minutes=2)

        if viewer.role == 'GUILD_MASTER':
            athletes = CustomUser.objects.filter(
                coach=viewer, role='RECRUIT').select_related('activity_status')
        elif viewer.role == 'SUPER_COACH':
            managed_coach_ids = viewer.managed_coaches.values_list('id', flat=True)
            athletes = CustomUser.objects.filter(
                coach__id__in=managed_coach_ids, role='RECRUIT').select_related('activity_status')
        else:
            return Response({'error': 'Forbidden'}, status=403)

        result = []
        for athlete in athletes:
            try:
                act = athlete.activity_status
                is_live = act.last_heartbeat and act.last_heartbeat >= two_minutes_ago
                result.append({
                    'id': athlete.id,
                    'username': athlete.username,
                    'is_live': is_live,
                    'activity_type': act.activity_type if is_live else 'idle',
                    'steps_live': act.steps_live if is_live else 0,
                    'last_heartbeat': str(act.last_heartbeat) if act.last_heartbeat else None,
                })
            except UserActivityStatus.DoesNotExist:
                result.append({
                    'id': athlete.id,
                    'username': athlete.username,
                    'is_live': False,
                    'activity_type': 'idle',
                    'steps_live': 0,
                    'last_heartbeat': None,
                })

        return Response(result)


# ── Workout Set Logging ───────────────────────────────────────────────────────
class LogSetView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        exercise_name = request.data.get('exercise_name', '')
        plan_name = request.data.get('workout_plan_name', '')
        reps = request.data.get('reps')
        weight_kg = request.data.get('weight_kg')
        effectiveness = request.data.get('effectiveness', 'Just Right')

        if not exercise_name or reps is None:
            return Response({'error': 'exercise_name and reps required'}, status=400)

        today = date.today()
        set_number = WorkoutSetLog.objects.filter(
            user=request.user,
            exercise_name=exercise_name,
            date=today
        ).count() + 1

        log = WorkoutSetLog.objects.create(
            user=request.user,
            exercise_name=exercise_name,
            workout_plan_name=plan_name,
            date=today,
            set_number=set_number,
            reps=int(reps),
            weight_kg=float(weight_kg) if weight_kg is not None else None,
            effectiveness=effectiveness,
        )

        today_count = WorkoutSetLog.objects.filter(
            user=request.user,
            exercise_name=exercise_name,
            date=today
        ).count()

        return Response({
            'id': log.id,
            'set_number': log.set_number,
            'today_set_count': today_count,
        }, status=status.HTTP_201_CREATED)


class MySetLogsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        cutoff = date.today() - timedelta(days=30)
        logs = WorkoutSetLog.objects.filter(
            user=request.user, date__gte=cutoff
        ).order_by('-logged_at')

        return Response([{
            'id': l.id,
            'exercise_name': l.exercise_name,
            'workout_plan_name': l.workout_plan_name,
            'date': str(l.date),
            'set_number': l.set_number,
            'reps': l.reps,
            'weight_kg': l.weight_kg,
            'effectiveness': l.effectiveness,
            'logged_at': str(l.logged_at),
        } for l in logs])


class AthleteSetLogsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, athlete_id):
        viewer = request.user
        try:
            athlete = CustomUser.objects.get(id=athlete_id, role='RECRUIT')
        except CustomUser.DoesNotExist:
            return Response({'error': 'Athlete not found'}, status=404)

        is_coach = viewer.role == 'GUILD_MASTER' and athlete.coach == viewer
        is_sc_direct = viewer.role == 'SUPER_COACH' and athlete.coach == viewer
        is_sc_managed = viewer.role == 'SUPER_COACH' and athlete.coach and athlete.coach.super_coach == viewer
        if not (is_coach or is_sc_direct or is_sc_managed):
            return Response({'error': 'Forbidden'}, status=403)

        cutoff = date.today() - timedelta(days=30)
        logs = WorkoutSetLog.objects.filter(
            user=athlete, date__gte=cutoff
        ).order_by('-logged_at')

        return Response([{
            'id': l.id,
            'exercise_name': l.exercise_name,
            'workout_plan_name': l.workout_plan_name,
            'date': str(l.date),
            'set_number': l.set_number,
            'reps': l.reps,
            'weight_kg': l.weight_kg,
            'effectiveness': l.effectiveness,
        } for l in logs])


# ── Athlete Analytics Summary (Coach/SC view) ────────────────────────────────
class AthleteAnalyticsSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, athlete_id):
        viewer = request.user
        try:
            athlete = CustomUser.objects.get(id=athlete_id, role='RECRUIT')
        except CustomUser.DoesNotExist:
            return Response({'error': 'Athlete not found'}, status=404)

        is_coach = viewer.role == 'GUILD_MASTER' and athlete.coach == viewer
        is_sc_direct = viewer.role == 'SUPER_COACH' and athlete.coach == viewer
        is_sc_managed = viewer.role == 'SUPER_COACH' and athlete.coach and athlete.coach.super_coach == viewer
        if not (is_coach or is_sc_direct or is_sc_managed):
            return Response({'error': 'Forbidden'}, status=403)

        today = date.today()
        cutoff_30 = today - timedelta(days=30)
        cutoff_7 = today - timedelta(days=7)

        # Latest body progress
        latest_body = BodyProgressEntry.objects.filter(user=athlete).order_by('-date').first()
        latest_body_data = None
        if latest_body:
            latest_body_data = {
                'date': str(latest_body.date),
                'weight_kg': latest_body.weight_kg,
                'body_fat_estimate': latest_body.body_fat_estimate,
            }

        # Last 30 days weight history
        body_entries = BodyProgressEntry.objects.filter(
            user=athlete, date__gte=cutoff_30
        ).order_by('date').values('date', 'weight_kg')
        weight_history = [{'date': str(e['date']), 'weight_kg': e['weight_kg']} for e in body_entries]

        # Last 7 days steps
        steps_data = DailyActivity.objects.filter(
            user=athlete, date__gte=cutoff_7
        ).order_by('date').values('date', 'steps', 'step_goal')
        steps_history = [{'date': str(e['date']), 'steps': e['steps'], 'goal': e['step_goal']} for e in steps_data]

        # Recent set logs (10)
        recent_sets = WorkoutSetLog.objects.filter(
            user=athlete
        ).order_by('-logged_at')[:10]
        set_logs = [{
            'exercise_name': l.exercise_name,
            'date': str(l.date),
            'set_number': l.set_number,
            'reps': l.reps,
            'weight_kg': l.weight_kg,
            'effectiveness': l.effectiveness,
        } for l in recent_sets]

        # Quest completions count
        from quests.models import QuestCompletion
        quest_count = QuestCompletion.objects.filter(recruit=athlete).count()

        # Live status
        two_min_ago = timezone.now() - timedelta(minutes=2)
        is_live = False
        activity_type = 'idle'
        try:
            act = athlete.activity_status
            is_live = bool(act.last_heartbeat and act.last_heartbeat >= two_min_ago)
            activity_type = act.activity_type if is_live else 'idle'
        except UserActivityStatus.DoesNotExist:
            pass

        return Response({
            'athlete': {
                'id': athlete.id,
                'username': athlete.username,
                'level': athlete.level,
                'xp': athlete.xp,
                'coins': athlete.coins,
            },
            'latest_body_progress': latest_body_data,
            'weight_history': weight_history,
            'steps_history': steps_history,
            'recent_set_logs': set_logs,
            'quest_completions': quest_count,
            'is_live': is_live,
            'activity_type': activity_type,
        })


# ── Self Transformations (Recruit self-view) ──────────────────────────────────
class SelfTransformationsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        today = date.today()
        cutoff_60 = today - timedelta(days=60)
        cutoff_30 = today - timedelta(days=30)

        base = request.build_absolute_uri('/')[:-1]

        # All body progress entries
        body_entries = BodyProgressEntry.objects.filter(user=user).order_by('-date')
        body_data = []
        for e in body_entries:
            d = {
                'id': e.id,
                'date': str(e.date),
                'weight_kg': e.weight_kg,
                'waist_cm': e.waist_cm,
                'chest_cm': e.chest_cm,
                'arms_cm': e.arms_cm,
                'thighs_cm': e.thighs_cm,
                'ai_analysis': e.ai_analysis,
                'body_fat_estimate': e.body_fat_estimate,
            }
            if e.photo_front:
                d['photo_front_url'] = base + e.photo_front.url
            if e.photo_side:
                d['photo_side_url'] = base + e.photo_side.url
            if e.photo_back:
                d['photo_back_url'] = base + e.photo_back.url
            body_data.append(d)

        # Last 60 days set logs
        set_logs_qs = WorkoutSetLog.objects.filter(
            user=user, date__gte=cutoff_60
        ).order_by('-logged_at')
        set_logs = [{
            'id': l.id,
            'exercise_name': l.exercise_name,
            'workout_plan_name': l.workout_plan_name,
            'date': str(l.date),
            'set_number': l.set_number,
            'reps': l.reps,
            'weight_kg': l.weight_kg,
            'effectiveness': l.effectiveness,
            'logged_at': str(l.logged_at),
        } for l in set_logs_qs]

        # Last 30 days daily activity
        daily_qs = DailyActivity.objects.filter(
            user=user, date__gte=cutoff_30
        ).order_by('date')
        daily_data = [{
            'date': str(a.date),
            'steps': a.steps,
            'step_goal': a.step_goal,
            'water_ml': a.water_ml,
            'water_goal_ml': a.water_goal_ml,
        } for a in daily_qs]

        return Response({
            'body_progress': body_data,
            'set_logs': set_logs,
            'daily_activity': daily_data,
        })
