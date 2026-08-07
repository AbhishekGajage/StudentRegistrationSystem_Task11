# Advertisement Modal Implementation

## Overview

This feature adds a dynamic **Advertisement / Notification Modal** to the Student Registration page. The modal is fully admin-managed — administrators can add, edit, delete, reorder, preview, and activate/deactivate advertisements from the Admin Panel without any code changes. When a student opens the Registration page, the highest-priority active advertisement is shown automatically as a modal.

---

## Default Admin Credentials

> ⚠️ **TODO:** Fill in the actual seeded values from your `Admin_Schema.sql`
> `INSERT INTO Admins (...)` statement. Paste that statement to me if you'd
> like me to fill this in for you automatically.

| Field    | Value                           |
|----------|---------------------------------|
| Username | admin                           |
| Password | Admin@123                       |

### Configuration (`Web.config`)

Update the following before running:

```xml
<connectionStrings>
  <add name="StudentDB" connectionString="Server=...;Database=...;..." providerName="System.Data.SqlClient" />
</connectionStrings>

<appSettings>
  <add key="SendGridApiKey" value="YOUR_KEY_HERE" />
  <add key="FromEmail" value="verified-sender@yourdomain.com" />
  <add key="AdminEmail" value="admin@yourdomain.com" />
  <add key="ProfilePhotoUploadPath" value="~/Uploads/Students/" />
  <add key="DocumentImageUploadPath" value="~/Uploads/DocumentImages/" />
  <add key="MaxDocumentImageSizeMB" value="5" />
</appSettings>
```

> **Security note:** never commit real API keys to source control. Rotate any
> key that has been shared or exposed, and consider environment-specific
> config transforms or a secrets manager for production.


## Table of Contents

1. [Features](#features)
2. [Project Structure](#project-structure)
3. [Database Schema](#database-schema)
4. [Admin Panel — Advertisement Management](#admin-panel--advertisement-management)
5. [Advertisement Edit Page](#advertisement-edit-page)
6. [Advertisement Preview Page](#advertisement-preview-page)
7. [Student Registration Modal](#student-registration-modal)
8. [Validation & Error Handling](#validation--error-handling)
9. [Setup Instructions](#setup-instructions)
10. [Configuration](#configuration)
11. [Known Behaviors / Design Notes](#known-behaviors--design-notes)

---

## Features

### Student-Facing
- Advertisement modal appears automatically when the Student Registration page loads.
- Fully responsive — works across desktop, tablet, and mobile.
- Non-blocking: includes a close button and does not interrupt the registration flow.
- Only shows an advertisement if at least one is marked **Active**; otherwise the modal does not render at all.
- Ties in Display Order fall back to "most recently created" so behavior is always predictable.

### Admin-Facing
- **Advertisement List page** — searchable, filterable (by status), sortable grid of all advertisements.
- **Add / Edit page** — create or update title, description (rich text via TinyMCE), banner image, display order, and status.
- **Live image preview** — banner preview updates instantly on file selection, before saving.
- **Full preview before saving** — modal preview of exactly how the ad will look (title, image, description, order, status), without a server round-trip.
- **Saved advertisement preview page** — dedicated read-only page, linked from the Actions menu, to view any saved advertisement.
- **Activate / Deactivate / Delete** — available directly from the list's Actions menu with confirmation prompts.
- **Sortable columns** — Title, Display Order, Status, Created Date, each with visual sort-direction indicators.

---

## Project Structure

| File | Purpose |
|---|---|
| `AdvertisementList.aspx` / `.aspx.cs` | Admin grid: search, filter, sort, paginate, and manage all advertisements. |
| `AdvertisementEdit.aspx` / `.aspx.cs` | Add/Edit form for a single advertisement, including image upload and pre-save preview. |
| `AdvertisementPreview.aspx` / `.aspx.cs` | Read-only preview page for a saved advertisement (title, banner, description, metadata). |
| `AdvertisementImageUpload.ashx` | Handler for TinyMCE in-editor image uploads within the description field. |
| `Register.aspx` / `.aspx.cs` | Student Registration page; loads and displays the active advertisement modal on load. |

---

## Database Schema

### `Advertisements` Table

| Column | Type | Notes |
|---|---|---|
| `AdvertisementID` | `INT IDENTITY PRIMARY KEY` | |
| `Title` | `NVARCHAR(200)` | Required. |
| `Description` | `NVARCHAR(MAX)` | Sanitized HTML from the rich text editor. |
| `ImagePath` | `NVARCHAR(300)` NULL | Relative path to the uploaded banner image; `NULL` if no image was uploaded. |
| `DisplayOrder` | `INT` DEFAULT `0` | Lower numbers are shown first. Ties break on `CreatedDate DESC`. |
| `Status` | `NVARCHAR(20)` | `'Active'` or `'Inactive'`. |
| `CreatedDate` | `DATETIME` | Set on insert. |
| `UpdatedDate` | `DATETIME` NULL | Set on every update. |
| `CreatedBy` | `NVARCHAR(100)` | Admin username who created the record. |

Run `Database/Advertisements_Schema.sql` against your database to create this table.

Sorting on the admin grid is restricted to a whitelist of columns (`Title`, `DisplayOrder`, `Status`, `CreatedDate`) to prevent SQL injection via `GridView` sort expressions.

---

## Admin Panel — Advertisement Management

**Page:** `AdvertisementList.aspx`

- **Search** by title (partial match).
- **Filter** by status (All / Active / Inactive).
- **Sort** any column by clicking its header; current sort direction is shown with an arrow and a status message (e.g. "Sorted by Display Order in ascending order").
- **Paginated** grid, 10 records per page.
- **Actions menu** (⋮) per row:
  - **Edit** — opens `AdvertisementEdit.aspx?id=...`
  - **Preview** — opens `AdvertisementPreview.aspx?id=...` in a new tab
  - **Activate / Deactivate** — toggles status with a confirmation prompt
  - **Delete** — permanently removes the record with a confirmation prompt
- **+ New Advertisement** button — opens the Edit page in "create" mode.

---

## Advertisement Edit Page

**Page:** `AdvertisementEdit.aspx`

**Fields:**
- Title (required)
- Description — rich text (TinyMCE, self-hosted), required, validated both client- and server-side
- Advertisement Image / Banner — optional upload (JPG, JPEG, PNG, GIF, WEBP; max size configurable, default 5 MB)
- Display Order — whole number, defaults to `0`
- Status — Active / Inactive

**Image handling:**
- File type and size are validated server-side before saving.
- Uploaded images are saved to a configurable folder (`~/Uploads/Advertisements/` by default) with a unique, timestamp-based filename.
- When editing, leaving the file field empty keeps the existing image.
- The banner preview box uses `style="display:none/block"` (not the server-side `Visible` property) so the `<img>` element always exists in the DOM and can be found by client-side JavaScript. `ClientIDMode="Static"` keeps its rendered `id` predictable for the preview script.

**Live preview before saving:**
- Selecting a file instantly shows a local preview (via `FileReader`), without a postback.
- A **Preview** button opens a modal showing the advertisement exactly as it will appear — title, current banner (whether newly selected or already saved), description, display order, and status — entirely client-side, with no server round-trip (final content is still sanitized server-side on Save).

---

## Advertisement Preview Page

**Page:** `AdvertisementPreview.aspx?id={AdvertisementID}`

- Read-only view of a saved advertisement: banner image (if present), title, description, display order, status (as a colored pill), and creation metadata.
- Reused directly from the Actions menu on the list page (opens in a new tab).
- Description is rendered as-is since it was already sanitized at save time.

---

## Student Registration Modal

**Page:** `Register.aspx`

- On page load, queries `Advertisements` for rows where `Status = 'Active'`, ordered by `DisplayOrder ASC, CreatedDate DESC`.
- The **first row** in that already-sorted result is the one featured in the modal — `DisplayOrder` is the primary control; `CreatedDate` only breaks ties between advertisements sharing the same order.
- If no active advertisement exists, the modal is not rendered.
- Includes a close button; dismissing the modal does not affect the registration form underneath.

---

## Validation & Error Handling

- **Required fields:** Title and Description are enforced via `RequiredFieldValidator` / `CustomValidator`, both client-side (JS) and server-side, so an editor containing only empty markup (e.g. `<p><br></p>`) does not pass as valid content.
- **Display Order:** restricted to whole numbers via `RegularExpressionValidator`.
- **Image upload:** extension whitelist and configurable max file size, checked server-side regardless of client-side `accept` attributes.
- **Description content:** run through `HtmlContentSanitizer` before being persisted, to strip unsafe markup while preserving the allowed rich-text formatting.
- **SQL safety:** all queries use parameterized `SqlParameter` values; the one dynamic `ORDER BY` clause (grid sorting) is restricted to a fixed column whitelist rather than accepting raw input.
- **Errors** (DB failures, upload failures, unexpected exceptions) are logged via `ErrorLogger` and shown to the admin as a friendly status message rather than a raw exception.

---

## Setup Instructions

1. Run `Database/Advertisements_Schema.sql` against your database to create the `Advertisements` table.
2. Ensure the upload folder exists and is writable by the application pool identity, or let the code create it automatically (`Server.MapPath` + `Directory.CreateDirectory`) on first upload.
3. Confirm `Scripts/tinymce/` contains the self-hosted TinyMCE build (already used by the Rich Text Editor feature — no separate install needed).
4. Add/verify the following `web.config` app settings (optional — sensible defaults are used if omitted):

```xml
<appSettings>
  <add key="AdvertisementImageUploadPath" value="~/Uploads/Advertisements/" />
  <add key="MaxAdvertisementImageSizeMB" value="5" />
</appSettings>
```

5. Deploy the pages listed in [Project Structure](#project-structure).
6. Log in to the Admin Panel and add at least one **Active** advertisement to see the modal appear on `Register.aspx`.

---

## Configuration

| Setting | Key | Default |
|---|---|---|
| Upload folder | `AdvertisementImageUploadPath` | `~/Uploads/Advertisements/` |
| Max image size (MB) | `MaxAdvertisementImageSizeMB` | `5` |

---

## Known Behaviors / Design Notes

- **All ads at Display Order 0:** the system falls back to newest-first, giving sensible default behavior with zero admin configuration. As soon as distinct order values are set, they take full priority.
- **Banner preview visibility** is controlled exclusively via CSS (`style["display"]`), never the server-side `Visible` property — this keeps the `<img>` element present in the DOM at all times so client-side JavaScript can reliably find and update it on both Create and Edit.
- **Pre-save preview** is intentionally client-side only (no DB round-trip), consistent with the same pattern used by the Rich Text Editor's Preview feature — final sanitization still happens server-side on Save.
