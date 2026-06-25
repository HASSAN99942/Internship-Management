from rest_framework import serializers


class AssignTeacherSerializer(serializers.Serializer):
    """Input for POST /api/v1/admin/assign-teacher/."""

    student_id = serializers.IntegerField()
    teacher_id = serializers.IntegerField(allow_null=True)
