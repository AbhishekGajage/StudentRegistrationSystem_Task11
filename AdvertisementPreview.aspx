<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="AdvertisementPreview.aspx.cs" Inherits="AdvertisementPreview" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Advertisement Preview</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" href="Styles/Site.css" />
    <link rel="stylesheet" href="Styles/Auth.css" />
    <link rel="icon" type="image/png" href="Images/favicon.png" />
    <style>
        .ad-preview-body { line-height: 1.6; }
        .ad-preview-body img { max-width: 100%; height: auto; }
        .ad-preview-body table { border-collapse: collapse; max-width: 100%; margin: 12px 0; }
        .ad-preview-body table td, .ad-preview-body table th { border: 1px solid #ccc; padding: 6px 10px; }
        .ad-preview-meta { color: #90a4ae; font-size: 13px; margin: -6px 0 22px; }
        .ad-preview-banner {
            width: 100%;
            max-width: 480px;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
            display: block;
            margin-bottom: 20px;
            object-fit: cover;
        }
        .status-pill {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 999px;
            font-size: 11.5px;
            font-weight: 600;
            color: #fff;
        }
        .pill-active   { background: #22c55e; }
        .pill-inactive { background: #9ca3af; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-wrapper">
            <div class="top-bar dashboard-top-bar">
                <div>
                    <h1>Advertisement Preview</h1>
                </div>
                <a href="AdvertisementList.aspx" class="btn btn-outline logout-btn no-print">&larr; All Advertisements</a>
            </div>

            <div class="card">
                <asp:Image ID="imgBanner" runat="server" CssClass="ad-preview-banner" Visible="false" />

                <h2><asp:Literal ID="litTitle" runat="server" /></h2>
                <p class="ad-preview-meta">
                    <asp:Literal ID="litMeta" runat="server" />
                </p>
                <div class="ad-preview-body">
                    <asp:Literal ID="litDescription" runat="server" Mode="PassThrough" />
                </div>
            </div>
        </div>
    </form>
</body>
</html>