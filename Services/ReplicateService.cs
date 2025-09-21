using System.Text.Json;
using System.Text;
using System.Text.Json.Serialization;

namespace GraniteChatbot.Services;

public class ReplicateService : IReplicateService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ReplicateService> _logger;

    public ReplicateService(HttpClient httpClient, IConfiguration configuration, ILogger<ReplicateService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<string> GenerateResponseAsync(string prompt)
    {
        try
        {
            var apiURL = _configuration["Replicate:ApiURL"];

            // Try multiple ways to get the API token (secure fallback)
            var apiToken = GetApiToken();

            if (string.IsNullOrEmpty(apiToken))
            {
                _logger.LogError("❌ Replicate API token not found");
                return "❌ Configuration Error: API token not found. Please check your environment variables or configuration.";
            }

            if (apiToken == "YOUR_REPLICATE_TOKEN_HERE" || apiToken == "PUT_YOUR_ACTUAL_REPLICATE_TOKEN_HERE")
            {
                _logger.LogError("❌ API token is still placeholder");
                return "❌ Configuration Error: Please set your actual Replicate API token.";
            }

            // Set up the request
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {apiToken}");

            // Replicate API payload for IBM Granite
            var payload = new
            {
                //version = "42a88c9b8e3e5e8cff16a2a9e7a75aa9d0b2e6c1",  // IBM Granite 3B Code Instruct version
                input = new
                {
                    prompt = prompt,
                    max_tokens = 500,
                    temperature = 0.7,
                    top_p = 0.9,
                    stop_sequences = new[] { "\n\nHuman:", "\n\nAssistant:" }
                }
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _logger.LogInformation($"Sending request to Replicate API with prompt: {prompt}");

            // Make the API call
            var response = await _httpClient.PostAsync(apiURL, content);

            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogError($"Replicate API error: {response.StatusCode} - {errorContent}");
                throw new HttpRequestException($"Replicate API returned {response.StatusCode}: {errorContent}");
            }

            var responseContent = await response.Content.ReadAsStringAsync();
            _logger.LogInformation($"Received response from Replicate API: {responseContent}");

            // Parse the response
            var replicateResponse = JsonSerializer.Deserialize<ReplicateApiResponse>(responseContent);

            if (replicateResponse == null)
            {
                throw new InvalidOperationException("Failed to parse Replicate API response.");
            }

            string status = replicateResponse.Status;
            string result = string.Empty;
            while (status == "starting" || status == "processing")
            {
                if (replicateResponse.Urls == null || string.IsNullOrEmpty(replicateResponse.Urls.Get))
                {
                    _logger.LogError("Replicate API response does not contain polling URL.");
                    return "I encountered an error while processing your request. Please try again.";
                }

                await Task.Delay(2000); // wait 2s before polling again

                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {apiToken}");
                var pollResponse = await _httpClient.GetAsync(replicateResponse.Urls.Get);
                pollResponse.EnsureSuccessStatusCode();

                var getJson = await pollResponse.Content.ReadAsStringAsync();
                var getResponse = JsonSerializer.Deserialize<ReplicateApiResponse>(getJson);

                if (getResponse == null)
                {
                    throw new InvalidOperationException("Failed to parse Replicate API response.");
                }

                status = getResponse.Status;

                if (status == "succeeded")
                {
                    result = getResponse.Output != null && getResponse.Output.Length > 0
                        ? getResponse.Output[0]
                        : "I apologize, but I couldn't generate a proper response. Please try rephrasing your question.";

                    return result;
                }
                else if (status == "failed" || status == "canceled")
                {
                    _logger.LogError($"Replicate prediction failed: {replicateResponse.Error}");
                    return "I encountered an error while processing your request. Please try again.";
                }
            }
            return result;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "HTTP error occurred while calling Replicate API");
            return "I'm having trouble connecting to the AI service. Please check your internet connection and try again.";
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Error parsing JSON response from Replicate API");
            return "I received an unexpected response from the AI service. Please try again.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error occurred while generating response");
            return "I encountered an unexpected error. Please try again later.";
        }
    }

    private string GetApiToken()
    {
        // Priority order for getting the API token:
        // 1. Environment variable (for production/container)
        // 2. Configuration (for development)

        // Check environment variable first (most secure)
        var envToken = Environment.GetEnvironmentVariable("Replicate__ApiToken");
        if (!string.IsNullOrEmpty(envToken))
        {
            _logger.LogInformation("✅ Using API token from environment variable");
            return envToken;
        }

        // Fallback to configuration
        var configToken = _configuration["Replicate:ApiToken"];
        if (!string.IsNullOrEmpty(configToken))
        {
            _logger.LogInformation("✅ Using API token from configuration");
            return configToken;
        }

        _logger.LogError("❌ No API token found in environment or configuration");
        return null!;
    }
}

// Response model for Replicate API
public class ReplicateApiResponse
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = "";

    [JsonPropertyName("model")]
    public string Model { get; set; } = "";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "";

    [JsonPropertyName("input")]
    public ReplicateInput? Input { get; set; }

    [JsonPropertyName("status")]
    public string Status { get; set; } = "";

    [JsonPropertyName("output")]
    public string[]? Output { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }

    [JsonPropertyName("urls")]
    public ReplicateUrls? Urls { get; set; }
}

public class ReplicateUrls
{
    [JsonPropertyName("cancel")]
    public string? Cancel { get; set; }

    [JsonPropertyName("get")]
    public string? Get { get; set; }

    [JsonPropertyName("stream")]
    public string? Stream { get; set; }

    [JsonPropertyName("web")]
    public string? Web { get; set; }
}

public class ReplicateInput
{
    [JsonPropertyName("prompt")]
    public string Prompt { get; set; } = "";

    [JsonPropertyName("max_tokens")]
    public int MaxTokens { get; set; } = 500;

    [JsonPropertyName("temperature")]
    public double Temperature { get; set; } = 0.7;

    [JsonPropertyName("top_p")]
    public double TopP { get; set; } = 0.9;

    [JsonPropertyName("stop_sequences")]
    public string[] StopSequences { get; set; } = new[] { "\n\nHuman:", "\n\nAssistant:" };
}