using System;
using System.Configuration;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>
/// Endpoint TinyMCE's image-upload toolbar button POSTs to when inserting an
/// inline image inside an advertisement's Description field. Mirrors
/// RichTextImageUpload.ashx exactly, but writes to a separate upload folder
/// so advertisement images and document images don't mix.
/// </summary>
public class AdvertisementImageUpload : IHttpHandler, System.Web.SessionState.IReadOnlySessionState
{
    private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";

        if (context.Session["AdminID"] == null)
        {
            context.Response.StatusCode = 401;
            WriteError(context, "Your session has expired. Please log in again.");
            return;
        }

        try
        {
            if (context.Request.Files.Count == 0)
            {
                context.Response.StatusCode = 400;
                WriteError(context, "No file was uploaded.");
                return;
            }

            HttpPostedFile file = context.Request.Files[0];
            string ext = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (Array.IndexOf(AllowedExtensions, ext) < 0)
            {
                context.Response.StatusCode = 400;
                WriteError(context, "Only JPG, JPEG, PNG, GIF, and WEBP images are allowed.");
                return;
            }

            double maxSizeMb;
            if (!double.TryParse(ConfigurationManager.AppSettings["MaxAdvertisementImageSizeMB"], out maxSizeMb))
            {
                maxSizeMb = 5;
            }

            if (file.ContentLength > maxSizeMb * 1024 * 1024)
            {
                context.Response.StatusCode = 400;
                WriteError(context, "Image must be smaller than " + maxSizeMb + " MB.");
                return;
            }

            string uploadFolder = ConfigurationManager.AppSettings["AdvertisementImageUploadPath"];
            if (string.IsNullOrWhiteSpace(uploadFolder))
            {
                uploadFolder = "~/Uploads/Advertisements/";
            }

            string physicalFolder = context.Server.MapPath(uploadFolder);
            if (!Directory.Exists(physicalFolder))
            {
                Directory.CreateDirectory(physicalFolder);
            }

            string uniqueFileName = "ADCONTENT_" + DateTime.Now.Ticks + ext;
            file.SaveAs(Path.Combine(physicalFolder, uniqueFileName));

            string relativeUrl = uploadFolder.TrimStart('~').TrimEnd('/') + "/" + uniqueFileName;

            context.Response.Write(new JavaScriptSerializer().Serialize(new { location = relativeUrl }));
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementImageUpload.ProcessRequest", ex);
            context.Response.StatusCode = 500;
            WriteError(context, "An unexpected error occurred while uploading the image.");
        }
    }

    private void WriteError(HttpContext context, string message)
    {
        context.Response.Write(new JavaScriptSerializer().Serialize(new { error = message }));
    }

    public bool IsReusable { get { return false; } }
}
