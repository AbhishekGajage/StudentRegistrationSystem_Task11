<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="AdvertisementList.aspx.cs" ValidateRequest="false" Inherits="AdvertisementList" %>

<!DOCTYPE html>
<html>
<head runat="server">
    <title>Manage Advertisements</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link rel="stylesheet" href="Styles/Site.css" />
    <link rel="stylesheet" href="Styles/Auth.css" />
    <link rel="icon" type="image/png" href="Images/favicon.png" />
    <style>
        .filter-bar { display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-end; margin: 14px 0; }
        .filter-bar .field { display: flex; flex-direction: column; min-width: 200px; }
        .filter-bar label { font-size: 13px; font-weight: 600; margin-bottom: 4px; }

        .grid-toolbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 4px 0 14px;
            flex-wrap: wrap;
            gap: 10px;
        }

        .record-count { display: block; margin: 0; }

        .status-info {
            background: #eaf1ff;
            border: 1px solid #b6d0ff;
            color: #1d4ed8;
            padding: 10px 14px;
            border-radius: 6px;
            font-size: 14px;
        }

        .candidate-grid { width: 100%; table-layout: fixed; border-collapse: collapse; font-size: 12.5px; }
        .candidate-grid th, .candidate-grid td { word-wrap: break-word; vertical-align: middle; text-align: center; }
        .candidate-grid td { word-break: break-word; overflow-wrap: break-word; }

        .candidate-grid thead th {
            background: #f8fafc;
            color: #475569;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .04em;
            word-break: keep-all;
            overflow-wrap: normal;
            padding: 10px 8px;
            border-bottom: 2px solid #e2e8f0;
        }
        .candidate-grid tbody td {
            padding: 10px 8px;
            border-bottom: 1px solid #eef1f5;
        }
        .candidate-grid tbody tr:last-child td { border-bottom: none; }
        .candidate-grid tbody tr:nth-child(even) { background: #fafbfc; }
        .candidate-grid tbody tr:hover { background: #f1f5f9; }

        .candidate-grid th:nth-child(1), .candidate-grid td:nth-child(1) { width: 6%;  }  /* Sr. No. */
        .candidate-grid th:nth-child(2), .candidate-grid td:nth-child(2) { width: 10%; }  /* Image */
        .candidate-grid th:nth-child(3), .candidate-grid td:nth-child(3) { width: 26%; text-align: left; }  /* Title */
        .candidate-grid th:nth-child(4), .candidate-grid td:nth-child(4) { width: 10%; }  /* Order */
        .candidate-grid th:nth-child(5), .candidate-grid td:nth-child(5) { width: 12%; }  /* Status */
        .candidate-grid th:nth-child(6), .candidate-grid td:nth-child(6) { width: 18%; }  /* Created */
        .candidate-grid th:nth-child(7), .candidate-grid td:nth-child(7) { width: 10%; }  /* Actions */

        .candidate-grid th a,
        .candidate-grid th a:visited,
        .candidate-grid th a:active {
            color: #475569;
            text-decoration: underline;
        }
        .candidate-grid th a:hover { color: #1d4ed8; }

        .ad-thumb {
            width: 44px;
            height: 44px;
            object-fit: cover;
            border-radius: 6px;
            display: block;
            margin: 0 auto;
            border: 1px solid #e2e8f0;
        }

        .status-pill {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 999px;
            font-size: 11.5px;
            font-weight: 600;
            color: #fff;
            white-space: nowrap;
        }
        .pill-active   { background: #22c55e; }
        .pill-inactive { background: #9ca3af; }

        /* Three-dot actions menu */
        .action-menu { position: relative; display: inline-block; }
        .action-menu-toggle {
            width: 30px;
            height: 30px;
            border-radius: 6px;
            border: 1px solid #d1d5db;
            background: #fff;
            font-size: 16px;
            line-height: 1;
            letter-spacing: 1px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #374151;
        }
        .action-menu-toggle:hover,
        .action-menu.open .action-menu-toggle { background: #f3f4f6; border-color: #9ca3af; }

        .action-menu-list {
            display: none;
            position: fixed;
            flex-direction: column;
            min-width: 150px;
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            box-shadow: 0 8px 20px rgba(0,0,0,0.15);
            padding: 6px 0;
            z-index: 1000;
        }
        .action-menu.open .action-menu-list { display: flex; }

        .action-menu-item {
            display: block;
            padding: 8px 14px;
            font-size: 13px;
            text-align: left;
            text-decoration: none;
            color: #1f2937;
            white-space: nowrap;
            background: none;
            border: none;
        }
        .action-menu-item:hover { background: #f3f4f6; }
        .action-menu-item.action-positive { color: #16a34a; }
        .action-menu-item.action-negative { color: #dc2626; }

        @media (max-width: 700px) {
            .candidate-grid { min-width: 680px; }
        }
        @media (max-width: 480px) {
            .filter-bar .field { flex: 1 1 100%; min-width: 0; }
            .filter-bar .field .btn { width: 100%; }
            .grid-toolbar { flex-direction: column; align-items: flex-start; }
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="page-wrapper">
            <div class="top-bar dashboard-top-bar">
                <div>
                    <h1>Manage Advertisements</h1>
                    <p>Control what students see on the registration page.</p>
                </div>
                <a href="AdminDashboard.aspx" class="btn btn-outline logout-btn no-print">&larr; Dashboard</a>
            </div>

            <div class="card dashboard-card">

                <div class="status-message-wrapper2">
                    <asp:Label ID="lblStatus" runat="server" CssClass="status-message" Visible="false"></asp:Label>
                    <asp:Label ID="lblSortStatus" runat="server" CssClass="status-message status-info" Visible="false"></asp:Label>
                </div>

                <div class="filter-bar no-print">
                    <div class="field">
                        <label>Search by Title</label>
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" placeholder="Search by title&hellip;" />
                    </div>
                    <div class="field">
                        <label>Status</label>
                        <asp:DropDownList ID="ddlStatusFilter" runat="server" CssClass="form-control">
                            <asp:ListItem Text="All" Value="" />
                            <asp:ListItem Text="Active" Value="Active" />
                            <asp:ListItem Text="Inactive" Value="Inactive" />
                        </asp:DropDownList>
                    </div>
                    <div class="field">
                        <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn btn-primary"
                            OnClick="btnSearch_Click" CausesValidation="false" />
                    </div>
                    <div class="field">
                        <asp:Button ID="btnResetSearch" runat="server" Text="Reset" CssClass="btn btn-outline"
                            OnClick="btnResetSearch_Click" CausesValidation="false" />
                    </div>
                </div>

                <div class="grid-toolbar no-print">
                    <div>
                        <asp:Label ID="lblCount" runat="server" CssClass="record-count" Text="0 advertisement(s) found" />
                    </div>
                    <div class="btn-row" style="margin:0;">
                        <asp:HyperLink ID="lnkNewAd" runat="server" NavigateUrl="AdvertisementEdit.aspx" CssClass="btn btn-success">
                            + New Advertisement
                        </asp:HyperLink>
                    </div>
                </div>

                <div class="table-scroll">
                    <asp:GridView ID="gvAds" runat="server" AutoGenerateColumns="false" CssClass="candidate-grid" GridLines="None"
                        DataKeyNames="AdvertisementID" EmptyDataText="No advertisements yet -- click '+ New Advertisement' to create one."
                        AllowSorting="true" AllowPaging="true" PageSize="10"
                        OnSorting="gvAds_Sorting" OnPageIndexChanging="gvAds_PageIndexChanging"
                        OnRowCommand="gvAds_RowCommand" OnRowCreated="gvAds_RowCreated">
                        <Columns>
                            <asp:TemplateField HeaderText="Sr. No.">
                                <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="Image">
                                <ItemTemplate>
                                    <img class="ad-thumb"
                                        src='<%# string.IsNullOrEmpty(Eval("ImagePath").ToString()) ? "Images/favicon.png" : ResolveUrl(Eval("ImagePath").ToString()) %>'
                                        alt="Ad image" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="Title" HeaderText="Title" SortExpression="Title" />
                            <asp:BoundField DataField="DisplayOrder" HeaderText="Order" SortExpression="DisplayOrder" />
                            <asp:TemplateField HeaderText="Status" SortExpression="Status">
                                <ItemTemplate>
                                    <span class='status-pill <%# "pill-" + Eval("Status").ToString().ToLower() %>'>
                                        <%# Eval("Status") %>
                                    </span>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:BoundField DataField="CreatedDate" HeaderText="Created Date"
                                SortExpression="CreatedDate" DataFormatString="{0:dd-MMM-yyyy hh:mm tt}" />
                            <asp:TemplateField HeaderText="Actions">
                                <ItemTemplate>
                                    <div class="action-menu">
                                        <button type="button" class="action-menu-toggle no-print"
                                            onclick="toggleActionMenu(this); return false;"
                                            aria-haspopup="true" aria-expanded="false" title="Actions">&#8942;</button>

                                        <div class="action-menu-list">
                                            <asp:LinkButton runat="server" CommandName="EditAd" CommandArgument='<%# Eval("AdvertisementID") %>'
                                                CssClass="action-menu-item">Edit</asp:LinkButton>
                                            <asp:HyperLink runat="server" NavigateUrl='<%# "AdvertisementPreview.aspx?id=" + Eval("AdvertisementID") %>'
    CssClass="action-menu-item" Target="_blank">View</asp:HyperLink>

                                            <asp:LinkButton runat="server" CommandName="Activate" CommandArgument='<%# Eval("AdvertisementID") %>'
                                                CssClass="action-menu-item action-positive"
                                                Visible='<%# Eval("Status").ToString() != "Active" %>'
                                                OnClientClick="return confirm('Activate this advertisement?');">Activate</asp:LinkButton>

                                            <asp:LinkButton runat="server" CommandName="Deactivate" CommandArgument='<%# Eval("AdvertisementID") %>'
                                                CssClass="action-menu-item action-negative"
                                                Visible='<%# Eval("Status").ToString() == "Active" %>'
                                                OnClientClick="return confirm('Deactivate this advertisement? It will stop showing on the registration page.');">Deactivate</asp:LinkButton>

                                            <asp:LinkButton runat="server" CommandName="DeleteAd" CommandArgument='<%# Eval("AdvertisementID") %>'
                                                CssClass="action-menu-item action-negative"
                                                OnClientClick="return confirm('Delete this advertisement? This action cannot be undone.');">Delete</asp:LinkButton>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </asp:GridView>
                </div>
            </div>
        </div>
    </form>

    <script>
        function closeAllActionMenus() {
            document.querySelectorAll('.action-menu.open').forEach(function (menu) {
                menu.classList.remove('open');
                var toggle = menu.querySelector('.action-menu-toggle');
                if (toggle) { toggle.setAttribute('aria-expanded', 'false'); }
            });
        }

        function toggleActionMenu(toggleBtn) {
            var menu = toggleBtn.closest('.action-menu');
            var list = menu.querySelector('.action-menu-list');
            var wasOpen = menu.classList.contains('open');

            closeAllActionMenus();

            if (!wasOpen) {
                var rect = toggleBtn.getBoundingClientRect();
                list.style.top = (rect.bottom + 4) + 'px';
                list.style.left = 'auto';
                list.style.right = (window.innerWidth - rect.right) + 'px';

                menu.classList.add('open');
                toggleBtn.setAttribute('aria-expanded', 'true');

                var listRect = list.getBoundingClientRect();
                if (listRect.bottom > window.innerHeight) {
                    list.style.top = (rect.top - listRect.height - 4) + 'px';
                }
            }
        }

        document.addEventListener('click', function (e) {
            if (!e.target.closest('.action-menu')) {
                closeAllActionMenus();
            }
        });
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape') { closeAllActionMenus(); }
        });
        window.addEventListener('resize', closeAllActionMenus);
        document.addEventListener('scroll', function (e) {
            if (e.target === document || e.target.classList.contains('table-scroll')) {
                closeAllActionMenus();
            }
        }, true);
    </script>
</body>
</html>
