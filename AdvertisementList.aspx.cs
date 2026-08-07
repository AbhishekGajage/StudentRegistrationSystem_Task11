using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class AdvertisementList : Page
{
    // ORDER BY can't be parameterized like a normal SQL value, so the sort
    // column has to be validated against a fixed whitelist instead -- never
    // concatenate GridView's SortExpression into SQL without this check.
    private static readonly HashSet<string> AllowedSortColumns = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        "Title", "DisplayOrder", "Status", "CreatedDate"
    };

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["AdminID"] == null)
        {
            Response.Redirect("AdminLogin.aspx");
            return;
        }

        if (!IsPostBack)
        {
            ViewState["SortExpr"] = "DisplayOrder";
            ViewState["SortDir"] = "ASC";
            BindGrid();
        }
    }

    private string GetSafeSortColumn(string expression)
    {
        return AllowedSortColumns.Contains(expression) ? expression : "DisplayOrder";
    }

    private void BindGrid()
    {
        try
        {
            string search = txtSearch.Text.Trim();
            string statusFilter = ddlStatusFilter.SelectedValue;
            string sortColumn = GetSafeSortColumn(ViewState["SortExpr"] as string ?? "DisplayOrder");
            string sortDirection = (ViewState["SortDir"] as string) == "DESC" ? "DESC" : "ASC";

            StringBuilder sql = new StringBuilder(
                "SELECT AdvertisementID, Title, ImagePath, DisplayOrder, Status, CreatedDate FROM Advertisements WHERE 1 = 1 ");
            var parameters = new List<SqlParameter>();

            if (!string.IsNullOrEmpty(search))
            {
                sql.Append(" AND Title LIKE @Search ");
                parameters.Add(new SqlParameter("@Search", "%" + search + "%"));
            }

            if (!string.IsNullOrEmpty(statusFilter))
            {
                sql.Append(" AND Status = @Status ");
                parameters.Add(new SqlParameter("@Status", statusFilter));
            }

            sql.Append(" ORDER BY ").Append(sortColumn).Append(" ").Append(sortDirection);
            if (!string.Equals(sortColumn, "CreatedDate", StringComparison.OrdinalIgnoreCase))
            {
                sql.Append(", CreatedDate DESC");
            }

            DataTable dt = DBHelper.ExecuteQuery(sql.ToString(), parameters.ToArray());
            gvAds.DataSource = dt;
            gvAds.DataBind();
            lblCount.Text = dt.Rows.Count + " advertisement(s) found";
            UpdateSortStatusMessage();
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementList.BindGrid", ex);
            ShowStatus("Unable to load advertisements right now. Please try again.", false);
        }
    }

    private void UpdateSortStatusMessage()
    {
        string sortColumn = GetSafeSortColumn(ViewState["SortExpr"] as string ?? "DisplayOrder");
        string sortDirection = (ViewState["SortDir"] as string) == "DESC" ? "DESC" : "ASC";

        string columnLabel;
        switch (sortColumn)
        {
            case "Title": columnLabel = "Title"; break;
            case "DisplayOrder": columnLabel = "Display Order"; break;
            case "Status": columnLabel = "Status"; break;
            case "CreatedDate": columnLabel = "Created Date"; break;
            default: columnLabel = sortColumn; break;
        }

        string directionLabel = (sortDirection == "ASC") ? "ascending" : "descending";

        lblSortStatus.Text = "Sorted by <strong>" + columnLabel + "</strong> in " + directionLabel + " order.";
        lblSortStatus.Visible = true;
    }

    // Column index matches declaration order in the markup: 0=Sr. No., 1=Image,
    // 2=Title, 3=Order, 4=Status, 5=Created Date, 6=Actions.
    protected void gvAds_RowCreated(object sender, GridViewRowEventArgs e)
    {
        if (e.Row.RowType != DataControlRowType.Header) return;

        string sortColumn = GetSafeSortColumn(ViewState["SortExpr"] as string ?? "DisplayOrder");
        string sortDirection = (ViewState["SortDir"] as string) == "DESC" ? "DESC" : "ASC";

        AddSortArrow(e.Row.Cells[2], "Title", sortColumn, sortDirection);
        AddSortArrow(e.Row.Cells[3], "DisplayOrder", sortColumn, sortDirection);
        AddSortArrow(e.Row.Cells[4], "Status", sortColumn, sortDirection);
        AddSortArrow(e.Row.Cells[5], "CreatedDate", sortColumn, sortDirection);
    }

    private void AddSortArrow(TableCell cell, string columnSortExpr, string currentExpr, string currentDir)
    {
        if (!string.Equals(columnSortExpr, currentExpr, StringComparison.OrdinalIgnoreCase)) return;

        string arrow = (currentDir == "ASC") ? "▲" : "▼";
        cell.Controls.Add(new LiteralControl("<span class='sort-arrow'>" + arrow + "</span>"));
    }

    protected void btnSearch_Click(object sender, EventArgs e)
    {
        gvAds.PageIndex = 0;
        BindGrid();
    }

    protected void btnResetSearch_Click(object sender, EventArgs e)
    {
        txtSearch.Text = "";
        ddlStatusFilter.SelectedIndex = 0;
        gvAds.PageIndex = 0;
        ViewState["SortExpr"] = "DisplayOrder";
        ViewState["SortDir"] = "ASC";
        BindGrid();
    }

    protected void gvAds_Sorting(object sender, GridViewSortEventArgs e)
    {
        string newSort = GetSafeSortColumn(e.SortExpression);
        string currentSort = ViewState["SortExpr"] as string;
        string currentDir = ViewState["SortDir"] as string ?? "ASC";

        ViewState["SortDir"] = (newSort == currentSort && currentDir == "ASC") ? "DESC" : "ASC";
        ViewState["SortExpr"] = newSort;

        BindGrid();
    }

    protected void gvAds_PageIndexChanging(object sender, GridViewPageEventArgs e)
    {
        gvAds.PageIndex = e.NewPageIndex;
        BindGrid();
    }

    protected void gvAds_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        int id;
        if (!int.TryParse(e.CommandArgument.ToString(), out id))
        {
            return;
        }

        switch (e.CommandName)
        {
            case "EditAd":
                Response.Redirect("AdvertisementEdit.aspx?id=" + id);
                break;
            case "Activate":
                SetStatus(id, "Active");
                BindGrid();
                break;
            case "Deactivate":
                SetStatus(id, "Inactive");
                BindGrid();
                break;
            case "DeleteAd":
                DeleteAdvertisement(id);
                BindGrid();
                break;
        }
    }

    private void SetStatus(int id, string status)
    {
        try
        {
            int rowsAffected = DBHelper.ExecuteNonQuery(
                "UPDATE Advertisements SET Status = @Status, UpdatedDate = @Now WHERE AdvertisementID = @Id",
                new SqlParameter("@Status", status),
                new SqlParameter("@Now", DateTime.Now),
                new SqlParameter("@Id", id));

            ShowStatus(rowsAffected > 0
                ? "Advertisement " + (status == "Active" ? "activated" : "deactivated") + " successfully."
                : "That advertisement no longer exists.", rowsAffected > 0);
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementList.SetStatus", ex);
            ShowStatus("Unable to update the advertisement status. Please try again.", false);
        }
    }

    private void DeleteAdvertisement(int id)
    {
        try
        {
            int rowsAffected = DBHelper.ExecuteNonQuery(
                "DELETE FROM Advertisements WHERE AdvertisementID = @Id",
                new SqlParameter("@Id", id));

            ShowStatus(rowsAffected > 0 ? "Advertisement deleted successfully." : "That advertisement no longer exists.", rowsAffected > 0);
        }
        catch (Exception ex)
        {
            ErrorLogger.Log("AdvertisementList.DeleteAdvertisement", ex);
            ShowStatus("Unable to delete the advertisement. Please try again.", false);
        }
    }

    private void ShowStatus(string message, bool success)
    {
        lblStatus.Text = (success ? "✅ " : "⚠️ ") + message;
        lblStatus.CssClass = "status-message " + (success ? "status-success" : "status-error");
        lblStatus.Visible = true;
    }
}
