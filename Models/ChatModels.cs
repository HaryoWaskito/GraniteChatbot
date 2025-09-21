namespace GraniteChatbot.Models;

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}

public class ChatResponse
{
    public string Response { get; set; } = string.Empty;
    public bool Success { get; set; } = true;
    public string Error { get; set; } = string.Empty;
}