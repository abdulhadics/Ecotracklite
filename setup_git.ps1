# PowerShell script to set up Git repository and push to GitHub

# Navigate to project directory
Set-Location "D:\vs cp programs\mobileapp"

# Initialize Git repository
& "C:\Program Files\Git\bin\git.exe" init

# Add all files to Git
& "C:\Program Files\Git\bin\git.exe" add .

# Create initial commit
& "C:\Program Files\Git\bin\git.exe" commit -m "Initial commit: EcoTrack Lite - Eco-friendly habit tracking app"

# Add remote origin
& "C:\Program Files\Git\bin\git.exe" remote add origin https://github.com/abdulhadics/Ecotracklite.git

# Set main branch
& "C:\Program Files\Git\bin\git.exe" branch -M main

# Push to GitHub
& "C:\Program Files\Git\bin\git.exe" push -u origin main

Write-Host "Repository setup complete! Your code has been pushed to GitHub."
