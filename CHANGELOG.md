# Release Notes
## Version 0.5.8 - 05/20/2024
### Bug Fixes
- Resolved and refined the UI on Mobile
- Resolved issue with text editing in database
- Improved appearance of empty text cells in kanban/calendar
- Resolved an issue where a page's more actions (delete, duplicate) did not work properly
- Resolved and inconsistency in padding on get started screen on Desktop

### New Features
- Improvement to the Callout block to insert new lines
- New settings page "Manage data" replaced the "Files" page
- New settings page "Workspace" replaced the "Appearance" and "Language" pages
- A custom implementation of a title bar for Windows users
- Added support for selecting Cards in kanban and performing grouped keyboard shortcuts
- Added support for default system font family
- Support for scaling the application up/down using a keyboard shortcut (CMD/CTRL + PLUS/MINUS)

## Version 0.5.7 - 05/10/2024
### Bug Fixes
- Resolved page opening issue on Android.
- Fixed text input inconsistency on Kanban board cards.

## Version 0.5.6 - 05/07/2024
### New Features
- Team collaboration is live! Add members to your workspace to edit and collaborate on pages together.
- Collaborate in real time on the same page with other members. Edits made by others will appear instantly.
- Create multiple workspaces for different kinds of content.
- Customize your entire page on mobile through the Page Style menu with options for layout, font, font size, emoji, and cover image.
- Open a row record as a full page.
### Bug Fixes
- Resolved issue with setting background color for the Simple Table block.
- Adjusted toolbar for various screen sizes.
- Added a request for photo permission before uploading images on mobile.
- Exported creation and last modification timestamps to CSV.

## Version 0.5.5 - 04/24/2024
### New Features
- Improved the display of code blocks with line numbers
- Added support for signing in using Magic Link
### Bug Fixes
- Fixed the database synchronization indicator issue
- Resolved the issue with opening the mentioned page on mobile
- Cleared the collaboration status when the user exits AppFlowy

## Version 0.5.4 - 04/08/2024
### New Features
- Introduced support for displaying a synchronization indicator within documents and databases to enhance user awareness of data sync status
- Revamped the select option cell editor in database
- Improved translations for Spanish, German, Kurdish, and Vietnamese
- Supported Android 6 and newer versions
### Bug Fixes
- Resolved an issue where twelve-hour time formats were not being parsed correctly in databases
- Fixed a bug affecting the user interface of the single select option filter
- Fixed various minor UI issues

## Version 0.5.3 - 03/21/2024
### New Features
- Added build support for 32-bit Android devices
- Introduced filters for KanBan boards for enhanced organization
- Introduced the new "Relations" column type in Grids
- Expanded language support with the addition of Greek
- Enhanced toolbar design for Mobile devices
- Introduced a command palette feature with initial support for page search
### Bug Fixes
- Rectified the issue of incomplete row data in Grids when adding new rows with active filters
- Enhanced the logic governing the filtering of number and select/multi-select fields for improved accuracy
- Implemented UI refinements on both Desktop and Mobile platforms, enriching the overall user experience of AppFlowy

## Version 0.5.2 - 03/13/2024
### Bug Fixes
- Import csv file.

## Version 0.5.1 - 03/11/2024
### New Features
- Introduced support for performing generic calculations on databases.
- Implemented functionality for easily duplicating calendar events.
- Added the ability to duplicate fields with cell data, facilitating smoother data management.
- Now supports customizing font styles and colors prior to typing.
- Enhanced the checklist user experience with the integration of keyboard shortcuts.
- Improved the dark mode experience on mobile devices.
### Bug Fixes
- Fixed an issue with some pages failing to sync properly.
- Fixed an issue where links without the http(s) scheme could not be opened, ensuring consistent link functionality.
- Fixed an issue that prevented numbers from being inserted before heading blocks.
- Fixed the inline page reference update mechanism to accurately reflect workspace changes.
- Fixed an issue that made it difficult to resize images in certain cases.
- Enhanced image loading reliability by clearing the image cache when images fail to load.
- Resolved a problem preventing the launching of URLs on some Linux distributions.

## Version 0.5.0 - 02/26/2024
### New Features
- Added support for scaling text on mobile platforms for better readability.
- Introduced a toggle for favorites directly from the documents' top bar.
- Optimized the image upload process and added error messaging for failed uploads.
- Implemented depth control for outline block components.
- New checklist task creation is now more intuitive, with prompts appearing on hover over list items in the row detail page.
- Enhanced sorting capabilities, allowing reordering and addition of multiple sorts.
- Expanded sorting and filtering options to include more field types like checklist, creation time, and modification time.
- Added support for field calculations within databases.
### Bug Fixes
- Fixed an issue where inserting an image from Unsplash in local mode was not possible.
- Fixed undo/redo functionality in lists.
- Fixed data loss issues when converting between block types.
- Fixed a bug where newly created rows were not being automatically sorted.
- Fixed issues related to deleting a sorting field or sort not removing existing sorts properly.
### Notes
- Windows 7, Windows 8, and iOS 11 are not yet supported due to the upgrade to Flutter 3.19.0.

## Version 0.4.9 - 02/17/2024
### Bug Fixes
- Resolved the issue that caused users to be redirected to the Sign In page

## Version 0.4.8 - 02/13/2024
### Bug Fixes
- Fixed a possible error when loading workspaces

## Version 0.4.6 - 02/03/2024
### Bug Fixes
- Fixed refresh token bug

## Version 0.4.5 - 02/01/2024
### Bug Fixes
- Fixed WebSocket connection issue

## Version 0.4.4 - 01/31/2024
### New Features
- Added functionality for uploading images to cloud storage.
- Enabled anonymous sign-in option for mobile platform users.
- Introduced the ability to customize cloud settings directly from the startup page.
- Added support for inserting reminders on the mobile platform.
- Overhauled the user interface on mobile devices, including improvements to the action bottom sheet, editor toolbar, database details page, and app bar.
- Implemented a shortcut (F2 key) to rename the current view.

### Bug Fixes
- Fixed an issue where the font family was not displaying correctly on the mobile platform.
- Resolved a problem with the mobile row detail title not updating correctly.
- Fixed issues related to deleting images and refactored the image actions menu for better usability.
- Fixed other known issues.

# Release Notes
## Version 0.4.3 - 01/16/2024
### Bug Fixes
- Fixed file name too long issue

## Version 0.4.2 - 01/15/2024
AppFlowy for Android is available to download on GitHub.
If you’ve been using our desktop app, it’s important to read [this guide](https://docs.appflowy.io/docs/guides/sync-desktop-and-mobile) before logging into the mobile app.
### New Features
- Enhanced RTL (Right-to-Left) support for mobile platforms.
- Optimized selection gesture system on mobile.
- Optimized the mobile toolbar menu.
- Improved reference menu (‘@’ menu).
- Updated privacy policy.
- Improved the data import process for AppFlowy by implementing a progress indicator and compressing the data to enhance efficiency.
- Enhanced the utilization of local disk space to optimize storage consumption.
### Bug Fixes
- Fixed sign-in cancellation issue on mobile.
- Resolved keyboard close bug on Android.


## Version 0.4.1 - 01/03/2024
### Bug fixes
- Fix import AppFlowy data folder

## Version 0.4.0 - 12/30/2023
1. Added capability to import data from an AppFlowy data folder. For detailed information, please see [AppFlowy Data Storage Documentation](https://docs.appflowy.io/docs/appflowy/product/data-storage).
2. Enhanced user interface and fixed various bugs.
3. Improved the efficiency of data synchronization in AppFlowy Cloud

## Version 0.3.9.1 - 12/07/2023

### Bug fixes
- Fix potential blank pages that may occur in an empty document

## Version 0.3.9 - 12/07/2023

### New Features
- Support inserting a new field to the left or right of an existing one

### Bug fixes
- Fix some emojis are shown in black/white
- Fix unable to rename a subpage of subpage

## Version 0.3.8 - 11/13/2023

### New Features
- Support hiding any stack in a board
- Support customizing page icons in menu
- Display visual hint when card contains notes
- Quick action for adding new stack to a board
- Support more ways of inserting page references in documents
- Shift + click on a checkbox to power toggle its children

### Bug fixes
- Improved color of the "Share"-button text
- Text overflow issue in Calendar properties
- Default font (Roboto) added to application
- Placeholder added for the editor inside a Card
- Toggle notifications in settings have been fixed
- Dialog for linking board/grid/calendar opens in correct position
- Quick add Card in Board at top, correctly adds a new Card at the top

## Version 0.3.7 - 10/30/2023

### New Features
- Support showing checklist items inline in row page.
- Support inserting date from slash menu.
- Support renaming a stack directly by clicking on the stack name.
- Show the detailed reminder content in the notification center.
- Save card order in Board view.
- Allow to hide the ungrouped stack.
- Segmented the checklist progress bar.

### Bug fixes
- Optimize side panel animation.
- Fix calendar with hidden date or title doesn't show options correctly.
- Fix the horizontal scroll bar disappears in Grid view.
- Improve setting tab UI in Grid view.
- Improve theme of the code block.
- Fix some UI issues.

## Version 0.3.6 - 10/16/2023

### New Features
- Support setting Markdown styles through keyboard shortcuts.
- Added Ukrainian language.
- Support auto-hiding sidebar feature, ensuring a streamlined view even when resizing to a smaller window.
- Support toggling the notifitcation on/off.
- Added Lemonade theme.

### Bug fixes
- Improve Vietnamese translations.
- Improve reminder feature.
- Fix some UI issues.

## Version 0.3.5 - 10/09/2023

### New Features
- Added support for browsing and inserting images from Unsplash.
- Revamp and unify the emoji picker throughout AppFlowy.

### Bug fixes
- Improve layout of the settings page.
- Improve design of the restore page banner.
- Improve UX of the reminders.
- Other UI fixes.

## Version 0.3.4 - 10/02/2023

### New Features
- Added support for creating a reminder.
- Added support for finding and replacing in the document page.
- Added support for showing the hidden fields in row detail page.
- Adjust the toolbar style in RTL mode.

### Bug fixes
- Improve snackbar UI design.
- Improve dandelion theme.
- Improve id-ID and pl-PL language translations.

## Version 0.3.3 - 09/24/2023

### New Features
- Added an end date field to the time cell in the database.
- Added Support for customizing the font family from GoogleFonts in the editor.
- Set the uploaded image to cover by default.
- Added Support for resetting the user icon on settings page
- Add Urdu language translations.

### Bug fixes
- Default colors for the blocks except for the callout were not transparent.
- Option/Alt + click to add a block above didn't work on the first line.
- Unable to paste HTML content containing `<mark>` tag.
- Unable to select the text from anywhere in the line.
- The selection in the editor didn't clear when editing the inline database.
- Added a bottom border to new property column in the database.
- Set minimum width of 50px for grid fields.

## Version 0.3.2 - 09/18/2023

### New Features

- Improve the performance of the editor, now it is much faster when editing a large document.
- Support for reordering the rows of the database on Windows.
- Revamp the row detail page of the database.
- Revamp the checklist cell editor of the database.

### Bug fixes

- Some UI issues

## Version 0.3.1 - 09/04/2023

### New Features

- Improve CJK (Chinese, Japanese, Korean) input method support.
- Share a database in CSV format.
- Support for aligning the block component with the toolbar.
- Support for editing name when creating a new page.
- Support for inserting a table in the document page.
- Database views allow for independent field visibility toggling.

### Bug fixes

- Paste multiple lines in code block.
- Some UI issues

## Version 0.3.0 - 08/22/2023

### New Features

- Improve paste features:
  - Paste HTML content from website.
  - Paste image from clipboard.

- Support Group by Date in Kanban Board.
- Notarize the macOS package, which is now verified by Apple.
- Add Persian language translations.

### Bug fixes

- Some UI issues

## Version 0.2.9 - 08/08/2023

### New Features

- Improve tab and shortcut, click with alt/option to open a page in new tab.
- Improve database tab bar UI.

### Bug fixes

- Add button and more action button of the favorite section doesn't work.
- Fix euro currency number format.
- Some UI issues

## Version 0.2.8 - 08/03/2023

### New Features

- Nestable personal folder that supports drag and drop
- Support for favorite folders.
- Support for sorting by date in Grid view.
- Add a duplicate button in the Board context menu.

### Bug fixes

- Improve readability in Callout
- Some UI issues

## Version 0.2.7 - 07/18/2023

### New Features

<img width="1147" src="https://github.com/AppFlowy-IO/AppFlowy/assets/11863087/ac464740-c685-4a85-ae99-1074c1c607e5">

- Open page in new tab
- Create toggle lists to keep things tidy in your pages
- Alt/Option + click to add a text block above

### Bug fixes

- Pasting into a Grid property crashed on Windows
- Double-click a link to open

## Version 0.2.6 - 07/11/2023

### New Features

- Dynamic load themes
- Inline math equation


## Version 0.2.5 - 07/02/2023

### New Features

- Insert local images
- Mention a page
- Outlines (Table of contents)
- Added support for aligning the image by image menu

### Bug fixes

- Some UI issues

## Version 0.2.4 - 06/23/2023

### Bug fixes:

- Unable to copy and paste a word
- Some UI issues

## Version 0.2.3 - 06/21/2023

### New Features

- Added support for creating multiple database views for existing database

## Version 0.2.2 - 06/15/2023

### New Features

- Added support for embedding a document in the database's row detail page
- Added support for inserting an emoji in the database's row detail page

### Other Updates

- Added language selector on the welcome page
- Added support for importing multiple markdown files all at once

## Version 0.2.1 - 06/11/2023

### New Features

- Added support for creating or referencing a calendar in the document
- Added `+` icon in grid's add field

### Other Updates

- Added vertical padding for progress bar
- Hide url cell accessory when the content is empty

### Bug fixes:

- Fixed unable to export markdown
- Fixed adding vertical padding for progress bar
- Fixed database view didn't update after the database layout changed.

## Version 0.2.0 - 06/08/2023

### New Features

- Improved checklists to support each cell having its own list
- Drag and drop calendar events
- Switch layouts (calendar, grid, kanban) of a database
- New database properties: 'Updated At' and 'Created At'
- Enabled hiding properties on the row detail page
- Added support for reordering and saving row order in different database views.
- Enabled each database view to have its own settings, including filter and sort options
- Added support to convert `“` (double quote) into a block quote
- Added support to convert `***` (three stars) into a divider
- Added support for an 'Add' button to insert a paragraph in a document and display the slash menu
- Added support for an 'Option' button to delete, duplicate, and customize block actions

### Other Updates

- Added support for importing v0.1.x documents and databases
- Added support for database import and export to CSV
- Optimized scroll behavior in documents.
- Redesigned the launch page

### Bug fixes

- Fixed bugs related to numbers
- Fixed issues with referenced databases in documents
- Fixed menu overflow issues in documents

### Data migration

The data format of this version is not compatible with previous versions. Therefore, to migrate your data to the new version, you need to use the export and import functions. Please follow the guide to learn how to export and import your data.

#### Export files in v0.1.6

https://github.com/AppFlowy-IO/AppFlowy/assets/11863087/0c89bf2b-cd97-4a7b-b627-59df8d2967d9

#### Import files in v0.2.0

https://github.com/AppFlowy-IO/AppFlowy/assets/11863087/7b392f35-4972-497a-8a7f-f38efced32e2

## Version 0.1.5 - 11/05/2023

### Bug Fixes

- Fix: calendar dates don't match with weekdays.
- Fix: sort numbers in Grid.

## Version 0.1.4 - 04/05/2023

### New features

- Use AppFlowy’s calendar views to plan and manage tasks and deadlines.
- Writing can be improved with the help of OpenAI.

## Version 0.1.3 - 24/04/2023

### New features

- Launch the official Dark Mode.
- Customize the font color and highlight color by setting a hex color value and an opacity level.

### Bug Fixes

- Fix: the slash menu can be triggered by all other keyboards than English.
- Fix: convert the single asterisk to italic text and the double asterisks to bold text.

## Version 0.1.2 - 03/28/2023

### Bug Fixes

- Fix: update calendar selected range.
- Fix: duplicate view.

## Version 0.1.1 - 03/21/2023

### New features

- AppFlowy brings the power of OpenAI into your AppFlowy pages. Ask AI to write anything for you in AppFlowy.
- Support adding a cover image to your page, making your pages beautiful.
- More shortcuts become available. Click on '?' at the bottom right to access our shortcut guide.

### Bug Fixes

- Fix some bugs

## Version 0.1.0 - 02/09/2023

### New features

- Support linking a Board or Grid into the Document page
- Integrate a callout plugin implemented by community members
- Optimize user interface

### Bug Fixes

- Fix some bugs

## Version 0.0.9.1 - 01/03/2023

### New features

- New theme
- Support changing text color of editor
- Optimize user interface

### Bug Fixes

- Fix some grid bugs

## Version 0.0.9 - 12/21/2022

### New features

- Enable the user to define where to store their data
- Support inserting Emojis through the slash command

### Bug Fixes

- Fix some bugs

## Version 0.0.8.1 - 12/09/2022

### New features

- Support following your default system theme
- Improve the filter in Grid

### Bug Fixes

- Copy/Paste

## Version 0.0.8 - 11/30/2022

### New features

- Table-view database
  - support column type: Checklist
- Board-view database
  - support column type: Checklist
- Customize font size: small, medium, large

## Version 0.0.7.1 - 11/30/2022

### Bug Fixes

- Fix some bugs

## Version 0.0.7 - 11/27/2022

### New features

- Support adding filters by the text/checkbox/single-select property in Grid

## Version 0.0.6.2 - 10/30/2022

- Fix some bugs

## Version 0.0.6.1 - 10/26/2022

### New features

- Optimize appflowy_editor dark mode style

### Bug Fixes

- Unable to copy the text with checkbox or link style

## Version 0.0.6 - 10/23/2022

### New features

- Integrate **appflowy_editor**

## Version 0.0.5.3 - 09/26/2022

### New features

- Open the next page automatically after deleting the current page
- Refresh the Kanban board after altering a property type

### Bug Fixes

- Fix switch board bug
- Fix delete the Kanban board's row error
- Remove duplicate time format
- Fix can't delete field in property edit panel
- Adjust some display UI issues

## Version 0.0.5.2 - 09/16/2022

### New features

- Enable adding a new card to the "No Status" group
- Fix some bugs

### Bug Fixes

- Fix cannot open AppFlowy error
- Fix delete the Kanban board's row error

## Version 0.0.5.1 - 09/14/2022

### New features

- Enable deleting a field in board
- Fix some bugs

## Version 0.0.5 - 09/08/2022

### New features - Kanban Board like Notion and Trello beta

Boards are the best way to manage projects & tasks. Use them to group your databases by select, multiselect, and checkbox.

<p align="left"><img src="https://user-images.githubusercontent.com/12026239/190055984-6efa2d7a-ee38-4551-859e-ee56388e1859.gif" width="1000px" /></p>

- Set up columns that represent a specific phase of the project cycle and use cards to represent each project/task
- Drag and drop a card from one phase/column to another phase/column
- Update database properties in the Board view by clicking on a property and making edits on the card

### Other Features & Improvements

- Settings allow users to change avatars
- Click and drag the right edge to resize your sidebar
- And many user interface improvements (link)

## Version 0.0.5 - beta.2 - beta.1 - 09/01/2022

### New features

- Board-view database
  - Support start editing after creating a new card
  - Support editing the card directly by clicking the edit button
  - Add the `No Status` column to display the cards while their status is empty

### Bug Fixes

- Optimize insert card animation
- Fix some UI bugs

## Version 0.0.5 - beta.1 - 08/25/2022

### New features

- Board-view database
  - Group by single select
  - drag and drop cards
  - insert / delete cards

![Aug-25-2022 16-22-38](https://user-images.githubusercontent.com/86001920/186614248-23186dfe-410e-427a-8cc6-865b1f79e074.gif)

## Version 0.0.4 - 06/06/2022

- Drag to adjust the width of a column
- Upgrade to Flutter 3.0
- Native support for M1 chip
- Date supports time formats
- New property: URL
- Keyboard shortcuts support for Grid: press Enter to leave the edit mode; control c/v to copy-paste cell values

### Bug Fixes

- Fixed some bugs

## Version 0.0.4 - beta.3 - 05/02/2022

- Drag to reorder app/ view/ field
- Row record opens as a page
- Auto resize the height of the row in the grid
- Support more number formats
- Search column options, supporting Single-select, Multi-select, and number format

![May-03-2022 10-03-00](https://user-images.githubusercontent.com/86001920/166394640-a8f1f3bc-5f20-4033-93e9-16bc308d7005.gif)

### Bug Fixes & Improvements

- Improved row/cell data cache
- Fixed some bugs

## Version 0.0.4 - beta.2 - 04/11/2022

- Support properties: Text, Number, Date, Checkbox, Select, Multi-select
- Insert / delete rows
- Add / delete / hide columns
- Edit property
  ![](https://user-images.githubusercontent.com/12026239/162753644-bf2f4e7a-2367-4d48-87e6-35e244e83a5b.png)

## Version 0.0.4 - beta.1 - 04/08/2022

v0.0.4 - beta.1 is pre-release

### New features

- Table-view database
  - support column types: Text, Checkbox, Single-select, Multi-select, Numbers
  - hide / delete columns
  - insert rows

## Version 0.0.3 - 02/23/2022

v0.0.3 is production ready, available on Linux, macOS, and Windows

### New features

- Dark Mode
- Support new languages: French, Italian, Russian, Simplified Chinese, Spanish
- Add Settings: Toggle on Dark Mode; Select a language
- Show device info
- Add tooltip on the toolbar icons

Bug fixes and improvements

- Increased height of action
- CPU performance issue
- Fix potential data parser error
- More foundation work for online collaboration
