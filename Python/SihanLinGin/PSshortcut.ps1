

$condaHook = "$env:USERPROFILE\AppData\Local\anaconda3\shell\condabin\conda-hook.ps1"
& $condaHook
(& $condaHook);(conda activate base)

Set-Location "C:\Users\sibbir.sihan\SSRepo\code_repo\Python\SihanLinGin"
python -m streamlit run SihanLinGinApp.py 

