using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using GraniteChatbot.Models;
using GraniteChatbot.Services;

namespace GraniteChatbot.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly IReplicateService _replicateService;

    public HomeController(ILogger<HomeController> logger, IReplicateService replicateService)
    {
        _logger = logger;
        _replicateService = replicateService;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Chat([FromBody] ChatRequest request)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Message))
            {
                return Json(new ChatResponse
                {
                    Response = "Please enter a message.",
                    Success = false
                });
            }

            // Call the Replicate service to get AI response
            var aiResponse = await _replicateService.GenerateResponseAsync(request.Message);

            var response = new ChatResponse
            {
                Response = aiResponse,
                Success = true
            };

            return Json(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing chat request");
            return Json(new ChatResponse
            {
                Response = "I apologize, but I'm having trouble processing your request right now. Please try again later.",
                Success = false,
                Error = ex.Message
            });
        }
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}