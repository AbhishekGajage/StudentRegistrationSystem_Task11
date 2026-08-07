<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="AdvertisementEdit.aspx.cs" ValidateRequest="false" Inherits="AdvertisementEdit" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Advertisement</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" href="Styles/Site.css" />
    <link rel="stylesheet" href="Styles/Auth.css" />
    <link rel="icon" type="image/png" href="Images/favicon.png" />
    <!--
        Self-hosted TinyMCE Community build -- same install already used by the
        Rich Text Editor feature. Shares the same Scripts/tinymce/ folder.
    -->
    <script src="Scripts/tinymce/tinymce.min.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
    <style>
        .preview-modal-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.55);
    z-index: 1000;
    align-items: center;
    justify-content: center;
    padding: 24px;
}
.preview-modal-overlay.open { display: flex; }
.preview-modal-box {
    background: #fff;
    border-radius: 10px;
    max-width: 900px;
    width: 100%;
    max-height: 85vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.preview-modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px 22px;
    border-bottom: 1px solid #eceff1;
}
.preview-modal-header h3 { margin: 0; font-size: 16px; }
.preview-modal-close { background: none; border: none; font-size: 20px; cursor: pointer; color: #666; }
.preview-modal-body { padding: 22px; overflow-y: auto; }
.preview-modal-body img { max-width: 100%; height: auto; }
        .banner-preview-row {
            display: flex;
            gap: 16px;
            align-items: flex-start;
            flex-wrap: wrap;
        }
        .banner-preview {
            width: 220px;
            max-width: 100%;
            border-radius: 8px;
            border: 1px solid #e2e8f0;
            object-fit: cover;
            display: block;
        }
        .banner-preview-empty {
            width: 220px;
            height: 120px;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #94a3b8;
            font-size: 12.5px;
            text-align: center;
            padding: 8px;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-wrapper">
            <div class="top-bar dashboard-top-bar">
                <div>
                    <h1><asp:Label ID="lblPageTitle" runat="server" Text="Create New Advertisement" /></h1>
                    <p>Shown to students as a modal on the registration page.</p>
                </div>
                <a href="AdvertisementList.aspx" class="btn btn-outline logout-btn no-print">&larr; All Advertisements</a>
            </div>

            <div class="status-message-wrapper">
                <asp:Label ID="lblStatus" runat="server" CssClass="status-message" Visible="false"></asp:Label>
            </div>

            <div class="card">
                <div class="form-group">
                    <label>Advertisement Title<span class="required">*</span></label>
                    <asp:TextBox ID="txtTitle" runat="server" CssClass="form-control" placeholder="e.g. Admissions Open for 2026" />
                    <asp:RequiredFieldValidator runat="server" ControlToValidate="txtTitle"
                        CssClass="field-error" Display="Dynamic" ErrorMessage="Advertisement title is required." ValidationGroup="AdGroup" />
                </div>

                <div class="form-group" style="margin-top:18px;">
                    <label>Description<span class="required">*</span></label>
                    <asp:TextBox ID="txtDescription" runat="server" TextMode="MultiLine" CssClass="tinymce-editor" />
                    <asp:CustomValidator ID="cvDescription" runat="server" CssClass="field-error" Display="Dynamic"
                        ErrorMessage="Advertisement description is required." OnServerValidate="cvDescription_ServerValidate"
                        ValidationGroup="AdGroup" ClientValidationFunction="validateDescriptionNotEmpty" />
                </div>

                <div class="form-group" style="margin-top:18px;">
                    <label>Advertisement Image / Banner</label>
                    <div class="banner-preview-row">
    <asp:Image ID="imgBannerPreview" runat="server" CssClass="banner-preview" 
        style="display:none;" ClientIDMode="Static" />

    <asp:Panel ID="pnlNoBanner" runat="server" CssClass="banner-preview-empty" ClientIDMode="Static">
        No image uploaded yet
    </asp:Panel>
    <div>
        <asp:FileUpload ID="fuBanner" runat="server" onchange="previewAdBanner(this)" />
        <p style="font-size:12px;color:#94a3b8;margin-top:6px;">JPG, JPEG, PNG, GIF, or WEBP &mdash; max 5&nbsp;MB. Leave empty to keep the current image when editing.</p>
        <asp:Label ID="lblBannerError" runat="server" CssClass="field-error"></asp:Label>
    </div>
</div>
                </div>

                <div class="form-grid" style="margin-top:18px;">
                    <div class="form-group">
                        <label>Display Order</label>
                        <asp:TextBox ID="txtDisplayOrder" runat="server" CssClass="form-control" Text="0" />
                        <asp:RegularExpressionValidator runat="server" ControlToValidate="txtDisplayOrder"
                            CssClass="field-error" Display="Dynamic" ErrorMessage="Display order must be a whole number."
                            ValidationExpression="^\d+$" ValidationGroup="AdGroup" />
                        <p style="font-size:12px;color:#94a3b8;margin-top:4px;">Lower numbers appear first in the "Show All" list.</p>
                    </div>

                    <div class="form-group">
                        <label>Status</label>
                        <asp:DropDownList ID="ddlStatus" runat="server" CssClass="form-control">
                            <asp:ListItem Text="Active" Value="Active" />
                            <asp:ListItem Text="Inactive" Value="Inactive" />
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="btn-row">
                    <asp:Button ID="btnSave" runat="server" Text="Save" CssClass="btn btn-success"
                        ValidationGroup="AdGroup" OnClick="btnSave_Click" OnClientClick="tinymce.triggerSave();" />
                    <asp:Button ID="btnReset" runat="server" Text="Reset" CssClass="btn btn-outline"
                        CausesValidation="false" OnClick="btnReset_Click" />
                     <button type="button" id="btnPreview" class="btn btn-secondary">Preview</button>
                </div>
            </div>
        </div>
    </form>
    <div class="preview-modal-overlay" id="previewOverlay">
    <div class="preview-modal-box">
        <div class="preview-modal-header">
            <h3>Preview</h3>
            <button type="button" class="preview-modal-close" id="btnClosePreview">&times;</button>
        </div>
        <div class="preview-modal-body">
            <img id="previewImage" class="banner-preview" style="display:none; margin-bottom:16px;" />
            <h2 id="previewTitle" style="margin:0 0 4px;"></h2>
            <p id="previewMeta" style="color:#90a4ae; font-size:13px; margin:0 0 18px;"></p>
            <div id="previewBody"></div>
        </div>
    </div>
</div>

    <script>
        tinymce.init({
            selector: '.tinymce-editor',
            license_key: 'gpl',
            height: 360,
            menubar: 'edit view insert format table tools',
            plugins: 'advlist autolink lists link image charmap preview anchor ' +
                     'searchreplace visualblocks code fullscreen insertdatetime ' +
                     'table help wordcount',
            toolbar:
                'undo redo | blocks fontfamily fontsize | ' +
                'bold italic underline strikethrough removeformat | ' +
                'forecolor backcolor | ' +
                'alignleft aligncenter alignright alignjustify | ' +
                'bullist numlist outdent indent | ' +
                'link image table charmap hr | ' +
                'searchreplace | fullscreen preview | help',
            branding: false,

            images_upload_url: 'AdvertisementImageUpload.ashx',
            automatic_uploads: true,
            file_picker_types: 'image',

            valid_elements:
                'p,br,span[style],div,strong,b,em,i,u,s,strike,sub,sup,' +
                'ul,ol,li,a[href|title|target|rel],img[src|alt|title|width|height|style],' +
                'table[style],thead,tbody,tr,td[colspan|rowspan|style],th[colspan|rowspan|style],' +
                'hr,h1,h2,h3,h4,h5,h6,blockquote,pre,code'
        });

        function validateDescriptionNotEmpty(source, args) {
            var editor = tinymce.get('<%= txtDescription.ClientID %>');
            var text = editor ? editor.getContent({ format: 'text' }).trim() : '';
    args.IsValid = text.length > 0;
}
function previewAdBanner(input) {
    if (!input.files || !input.files[0]) return;
    var reader = new FileReader();
    reader.onload = function(e) {
        var img = document.getElementById('imgBannerPreview');
        var empty = document.getElementById('pnlNoBanner');
        img.src = e.target.result;
        img.style.display = 'block';
        if (empty) empty.style.display = 'none';
    };
    reader.readAsDataURL(input.files[0]);
}
$(function() {
    $('#btnPreview').on('click', function() {
        var editor = tinymce.get('<%= txtDescription.ClientID %>');
        var descHtml = editor ? editor.getContent() : '';
        var title = $('#<%= txtTitle.ClientID %>').val();
        var displayOrder = $('#<%= txtDisplayOrder.ClientID %>').val();
        var status = $('#<%= ddlStatus.ClientID %>').val();

        var bannerImg = document.getElementById('imgBannerPreview');
        var previewImg = document.getElementById('previewImage');

        if (bannerImg && bannerImg.style.display !== 'none' && bannerImg.src) {
            previewImg.src = bannerImg.src;
            previewImg.style.display = 'block';
        } else {
            previewImg.style.display = 'none';
        }

        $('#previewTitle').text(title || '(Untitled Advertisement)');
        $('#previewMeta').text('Display Order: ' + displayOrder + '  |  Status: ' + status);
        $('#previewBody').html(descHtml);

        $('#previewOverlay').addClass('open');
    });

    $('#btnClosePreview, #previewOverlay').on('click', function(e) {
        if (e.target.id === 'btnClosePreview' || e.target.id === 'previewOverlay') {
            $('#previewOverlay').removeClass('open');
        }
            });
        });
    </script>
</body>
</html>
