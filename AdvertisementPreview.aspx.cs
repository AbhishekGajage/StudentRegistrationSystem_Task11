using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;

public partial class AdvertisementPreview : Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["AdminID"] == null)
        {
            Response.Redirect("AdminLogin.aspx");
            return;
        }

        int id;
        if (!int.TryParse(Request.QueryString["id"], out id))
        {
            litTitle.Text = "No advertisement specified";
            return;
        }

        try
        {
            DataTable dt = DBHelper.ExecuteQuery(
                "SELECT Title, Description, ImagePath, DisplayOrder, Status, CreatedDate, CreatedBy FROM Advertisements WHERE AdvertisementID = @Id",
                new SqlParameter("@Id", id));

            if (dt.Rows.Count == 0)
            {
                litTitle.Text = "Advertisement not found";
                return;
            }

            DataRow row = dt.Rows[0];
            litTitle.Text = System.Web.HttpUtility.HtmlEncode(row["Title"].ToString());

            string imagePath = row["ImagePath"] == DBNull.Value ? null : row["ImagePath"].ToString();
            if (!string.IsNullOrEmpty(imagePath))
            {
                imgBanner.ImageUrl = ResolveUrl(imagePath);
                imgBanner.Visible = true;
            }

            string status = row["Status"].ToString();
            string statusPill = "<span class='status-pill " + (status == "Active" ? "pill-active" : "pill-inactive") + "'>" +
                System.Web.HttpUtility.HtmlEncode(status) + "</span>";

            string meta = "Display Order: " + System.Web.HttpUtility.HtmlEncode(row["DisplayOrder"].ToString()) +
                " &middot; Status: " + statusPill +
                " &middot; Created by " + System.Web.HttpUtility.HtmlEncode(row["CreatedBy"].ToString()) +
                " on " + Convert.ToDateTime(row["CreatedDate"]).ToString("dd-MMM-yyyy hh:mm tt");

            litMeta.Text = meta;

            // Description was already run through HtmlContentSanitizer at Save time
            // (see AdvertisementEdit.aspx.cs), so it's safe to render as-is here.
            litDescription.Text = row["Description"].ToString();
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementPreview.Load", ex);
            litTitle.Text = "Unable to load this advertisement";
            litDescription.Text = "<p>Please try again in a moment.</p>";
        }
    }
}