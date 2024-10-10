# Input bindings are passed in via param block.
param([byte[]] $InputBlob, $TriggerMetadata)

# Write out the blob name and size to the information log.
Write-Host "PowerShell Blob trigger function Processed blob! Name: $($TriggerMetadata.Name) Size: $($InputBlob.Length) bytes"

# Call the face detection REST API
$APIURI = "$Env:FACE_ENDPOINT/face/v1.0/detect?overload=stream&recognitionModel=recognition_04&returnRecognitionModel=false&detectionModel=detection_03"
$APIHeaders = @{
    "Content-Type" = "application/octet-stream"
    "Ocp-Apim-Subscription-Key" = "$Env:FACE_APIKEY"
}

$response = Invoke-RestMethod -Uri $APIURI -Method POST -Headers $APIHeaders -Body $InputBlob

# Crop the image
$image = [System.Drawing.Image]::FromStream([System.IO.MemoryStream]::new($InputBlob))

# $cropArea = New-Object System.Drawing.Rectangle([int]$response.FaceRectangle.Left, [int]$response.FaceRectangle.Top, [int]$response.FaceRectangle.Width, [int]$response.FaceRectangle.Height)
# $destinationArea = New-Object System.Drawing.Rectangle(0, 0, [int]$response.FaceRectangle.Width, [int]$response.FaceRectangle.Height)
$cropArea = New-Object System.Drawing.Rectangle([int]$response.FaceRectangle.Top, [int]$response.FaceRectangle.Left, [int]$response.FaceRectangle.Height, [int]$response.FaceRectangle.Width)
$destinationArea = New-Object System.Drawing.Rectangle(0, 0, [int]$response.FaceRectangle.Height, [int]$response.FaceRectangle.Width)
$croppedImage = New-Object System.Drawing.Bitmap($cropArea.Width, $cropArea.Height)

$graphics = [System.Drawing.Graphics]::FromImage($croppedImage)
$graphics.DrawImage($image, $destinationArea, $cropArea, [System.Drawing.GraphicsUnit]::Pixel)

$croppedImageStream = New-Object System.IO.MemoryStream
$croppedImage.Save($croppedImageStream, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Output the cropped image
Push-OutputBinding -Name OutputBlob -Value $croppedImageStream.ToArray()

$graphics.Dispose()
$croppedImage.Dispose()
$image.Dispose()