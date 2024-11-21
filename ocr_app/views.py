from django.shortcuts import render

# Create your views here.
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import PhotoCard, Passport, DriverLicense
from .serializers import PhotoCardSerializer, PassportSerializer, DriverLicenseSerializer
from django.http import JsonResponse

def root_view(request):
    return JsonResponse({"message": "Welcome to the OCR Backend!"})

@api_view(['GET', 'POST'])
def photo_card_view(request):
    if request.method == 'GET':
        photo_cards = PhotoCard.objects.all()
        serializer = PhotoCardSerializer(photo_cards, many=True)
        return Response(serializer.data)
    
    if request.method == 'POST':
        serializer = PhotoCardSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)


@api_view(['GET', 'POST'])
def passport_view(request):
    if request.method == 'GET':
        passports = Passport.objects.all()
        serializer = PassportSerializer(passports, many=True)
        return Response(serializer.data)
    
    if request.method == 'POST':
        serializer = PassportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)


@api_view(['GET', 'POST'])
def driver_license_view(request):
    if request.method == 'GET':
        driver_licenses = DriverLicense.objects.all()
        serializer = DriverLicenseSerializer(driver_licenses, many=True)
        return Response(serializer.data)
    
    if request.method == 'POST':
        serializer = DriverLicenseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)
