# jxl-bulk-convert
Multithreaded PS script to mass compress jepg and png files to jxl. 
This will 1) copy original image to a compressed .jxl file > 2) validate new .jxl file was created > 3) delete original image only if step 2 is successfull. If step 2 was not successful, it'll skip that file and move on to the next.
***
First download cjxl.exe by selecting the archive for your OS here: https://github.com/libjxl/libjxl/releases/latest
Mind that this project is a PoserShell script so you should be selecting Windows.
Extract the archive to a folder of your choice. I used D:\apps\jxl . This path is the $CjxlPath variable in the script. Add this path to your PATH variable for best results.
Open script for editing.
Point the $InputPath variable to your images folder. It'll convert jpg, jpeg, and png files to jxl. 
Png is lossless and cannot be reduced in quality during this conversion, but jpg/jpeg will be reduced to 90% quality, saving more space than the simple compression applied to png files. You can change the jpg/jpeg quality by adjusting the number 90 in the script. You will get more errors and failed conversions the lower you go. I see no failed conversions at 90%, and you can go up to 100% for a lossless compression. But I see many failed conversions at 80%, which seems to be an issue with the cjxl.exe and specific images. 
***
Warning! After you convert images to .jxl you need to enable jxl support for Windows to still view thumbnails and such in file explorer, or use Windows photo apps to view files. On Windows 11 24H2, install JXL support through the Microsoft Store. You may be able to enable it as an optional feature, but Microsoft appears to have moved that to the store.
