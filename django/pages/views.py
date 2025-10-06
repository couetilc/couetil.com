from django.shortcuts import render

def home(request):
    return render(request, 'home.html')

def about(request):
    return render(request, 'about.html')

def portfolio(request):
    return render(request, 'portfolio.html')
