public void SanitiseText(char text[256])
{
    ReplaceString(text, 256, "@", "", false);
    ReplaceString(text, 256, "`", "", false);
    ReplaceString(text, 256, "\\", "", false);
}