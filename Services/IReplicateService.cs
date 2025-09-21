namespace GraniteChatbot.Services;

public interface IReplicateService
{
    Task<string> GenerateResponseAsync(string prompt);
}
