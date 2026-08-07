using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text.RegularExpressions;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class AdvertisementEdit : Page
{
    private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };

    private int? AdvertisementId
    {
        get
        {
            int id;
            return int.TryParse(Request.QueryString["id"], out id) ? (int?)id : null;
        }
    }

    // Tracks the existing image path when editing, so Save can keep it if no
    // new file was chosen. Stored in ViewState rather than re-queried, since
    // it must survive the postback triggered by clicking Save.
    private string ExistingImagePath
    {
        get { return ViewState["ExistingImagePath"] as string; }
        set { ViewState["ExistingImagePath"] = value; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["AdminID"] == null)
        {
            Response.Redirect("AdminLogin.aspx");
            return;
        }

        if (!IsPostBack)
        {
            if (AdvertisementId.HasValue)
            {
                lblPageTitle.Text = "Edit Advertisement";
                btnSave.Text = "Update";
                LoadAdvertisement(AdvertisementId.Value);
            }
            else
            {
                lblPageTitle.Text = "Create New Advertisement";
                btnSave.Text = "Save";
                pnlNoBanner.Visible = true;
                
            }
        }
    }

    private void LoadAdvertisement(int id)
    {
        try
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT Title, Description, ImagePath, DisplayOrder, Status FROM Advertisements WHERE AdvertisementID = @Id",
                new SqlParameter("@Id", id));

            if (dt.Rows.Count == 0)
            {
                ShowStatus("That advertisement no longer exists.", false);
                btnSave.Enabled = false;
                return;
            }

            DataRow row = dt.Rows[0];
            txtTitle.Text = row["Title"].ToString();
            txtDescription.Text = row["Description"].ToString();
            txtDisplayOrder.Text = row["DisplayOrder"].ToString();
            ddlStatus.SelectedValue = row["Status"].ToString();

            string imagePath = row["ImagePath"] == DBNull.Value ? null : row["ImagePath"].ToString();
            ExistingImagePath = imagePath;

            if (!string.IsNullOrEmpty(imagePath))
            {
                imgBannerPreview.ImageUrl = ResolveUrl(imagePath);
                imgBannerPreview.Style["display"] = "block";
                pnlNoBanner.Visible = false;
            }
            else
            {
                imgBannerPreview.Style["display"] = "none";
                pnlNoBanner.Visible = true;
            }
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementEdit.LoadAdvertisement", ex);
            ShowStatus("Unable to load this advertisement right now. Please try again.", false);
            btnSave.Enabled = false;
        }
    }

    protected void cvDescription_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string stripped = Regex.Replace(txtDescription.Text ?? "", "<.*?>", string.Empty).Trim();
        args.IsValid = !string.IsNullOrWhiteSpace(stripped);
    }

    protected void btnSave_Click(object sender, EventArgs e)
    {
        if (!Page.IsValid)
        {
            return;
        }

        string title = txtTitle.Text.Trim();
        int displayOrder;
        if (!int.TryParse(txtDisplayOrder.Text.Trim(), out displayOrder))
        {
            displayOrder = 0;
        }
        string status = ddlStatus.SelectedValue;

        string sanitizedDescription;
        try
        {
            sanitizedDescription = HtmlContentSanitizer.Sanitize(txtDescription.Text);
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementEdit.Sanitize", ex);
            ShowStatus("There was a problem processing the advertisement description. Please try again.", false);
            return;
        }

        // ---- Handle the banner image upload (optional -- keep existing on edit if left blank) ----
        string imagePath = AdvertisementId.HasValue ? ExistingImagePath : null;

        if (fuBanner.HasFile)
        {
            string ext = Path.GetExtension(fuBanner.FileName).ToLowerInvariant();
            if (Array.IndexOf(AllowedExtensions, ext) < 0)
            {
                lblBannerError.Text = "Only JPG, JPEG, PNG, GIF, and WEBP images are allowed.";
                return;
            }

            double maxSizeMb;
            if (!double.TryParse(ConfigurationManager.AppSettings["MaxAdvertisementImageSizeMB"], out maxSizeMb))
            {
                maxSizeMb = 5;
            }

            if (fuBanner.PostedFile.ContentLength > maxSizeMb * 1024 * 1024)
            {
                lblBannerError.Text = "Image must be smaller than " + maxSizeMb + " MB.";
                return;
            }

            try
            {
                string uploadFolder = ConfigurationManager.AppSettings["AdvertisementImageUploadPath"];
                if (string.IsNullOrWhiteSpace(uploadFolder))
                {
                    uploadFolder = "~/Uploads/Advertisements/";
                }

                string physicalFolder = Server.MapPath(uploadFolder);
                if (!Directory.Exists(physicalFolder))
                {
                    Directory.CreateDirectory(physicalFolder);
                }

                string uniqueFileName = "AD_" + DateTime.Now.Ticks + ext;
                fuBanner.SaveAs(Path.Combine(physicalFolder, uniqueFileName));

                imagePath = uploadFolder.TrimEnd('/') + "/" + uniqueFileName;
            }
            catch (Exception ex)
            {
                ErrorLogger.Log("AdvertisementEdit.UploadBanner", ex);
                lblBannerError.Text = "Unable to upload the image. Please try again.";
                return;
            }
        }

        string adminUsername = Session["AdminUsername"] as string ?? "Admin";

        try
        {
            if (AdvertisementId.HasValue)
            {
                int rowsAffected = DBHelper.ExecuteNonQuery(
                    @"UPDATE Advertisements
                      SET Title = @Title, Description = @Description, ImagePath = @ImagePath,
                          DisplayOrder = @DisplayOrder, Status = @Status, UpdatedDate = @Now
                      WHERE AdvertisementID = @Id",
                    new SqlParameter("@Title", title),
                    new SqlParameter("@Description", sanitizedDescription),
                    new SqlParameter("@ImagePath", (object)imagePath ?? DBNull.Value),
                    new SqlParameter("@DisplayOrder", displayOrder),
                    new SqlParameter("@Status", status),
                    new SqlParameter("@Now", DateTime.Now),
                    new SqlParameter("@Id", AdvertisementId.Value));

                ShowStatus(rowsAffected > 0 ? "Advertisement updated successfully." : "That advertisement no longer exists.", rowsAffected > 0);
                ExistingImagePath = imagePath;
            }
            else
            {
                DBHelper.ExecuteNonQuery(
                    @"INSERT INTO Advertisements (Title, Description, ImagePath, DisplayOrder, Status, CreatedDate, CreatedBy)
                      VALUES (@Title, @Description, @ImagePath, @DisplayOrder, @Status, @Now, @CreatedBy)",
                    new SqlParameter("@Title", title),
                    new SqlParameter("@Description", sanitizedDescription),
                    new SqlParameter("@ImagePath", (object)imagePath ?? DBNull.Value),
                    new SqlParameter("@DisplayOrder", displayOrder),
                    new SqlParameter("@Status", status),
                    new SqlParameter("@Now", DateTime.Now),
                    new SqlParameter("@CreatedBy", adminUsername));

                ShowStatus("Advertisement created successfully.", true);
                txtTitle.Text = "";
                txtDescription.Text = "";
                txtDisplayOrder.Text = "0";
                ddlStatus.SelectedValue = "Active";
                imgBannerPreview.Style["display"] = "none";
                pnlNoBanner.Visible = true;
            }
        }
        catch (SqlException ex)
        {
            ErrorLogger.Log("AdvertisementEdit.SaveAdvertisement.DB", ex);
            ShowStatus("A database error occurred while saving. Please try again.", false);
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementEdit.SaveAdvertisement.Unexpected", ex);
            ShowStatus("An unexpected error occurred while saving. Please try again.", false);
        }
    }

    protected void btnReset_Click(object sender, EventArgs e)
    {
        Response.Redirect(AdvertisementId.HasValue
            ? "AdvertisementEdit.aspx?id=" + AdvertisementId.Value
            : "AdvertisementEdit.aspx");
    }

    private void ShowStatus(string message, bool success)
    {
        lblStatus.Text = (success ? "✅ " : "⚠️ ") + message;
        lblStatus.CssClass = "status-message " + (success ? "status-success" : "status-error");
        lblStatus.Visible = true;
    }
}
