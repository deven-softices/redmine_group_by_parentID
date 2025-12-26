# Redmine Group by Parent Task Plugin

A Redmine plugin that enhances issue grouping by parent task, displaying both parent ID and title while maintaining correct time aggregation and subtask counts.

## Features

- ✅ **Group by Parent Task** - Group issues by their parent task with enhanced display
- ✅ **Parent ID + Title Display** - Shows "#123: Parent Task Title" instead of just the ID
- ✅ **Correct Aggregation** - Maintains accurate estimated time, spent time, and subtask counts
- ✅ **Customizable Sorting** - Configure sort order for both parent tasks and subtasks
- ✅ **Default Grouping Option** - Optionally apply parent grouping by default across all projects
- ✅ **Clickable Parent Links** - Parent task titles are clickable links to the parent issue

## Installation

1. Clone the repository into your Redmine plugins directory:
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/deven-softices/redmine_group_by_parentID.git parent_grouping
   ```

2. Restart Redmine:
   ```bash
   # For Passenger/Apache
   touch tmp/restart.txt

   # For Docker
   docker-compose restart redmine

   # For development server
   bundle exec rails server
   ```

3. Configure the plugin:
   - Go to **Administration → Plugins → Redmine Group by Parent Task → Configure**
   - Adjust settings as needed

## Configuration

### Plugin Settings

Access plugin settings via **Administration → Plugins → Redmine Group by Parent Task → Configure**

| Setting | Description | Default |
|---------|-------------|---------|
| **Enable hierarchical sorting** | Enables grouping and sorting by parent task | Enabled |
| **Apply parent grouping by default** | Automatically groups all issue lists by parent task | Disabled |
| **Parent task sort order** | Sort order for parent task groups (Ascending/Descending) | Descending |
| **Subtask sort order** | Sort order for subtasks within each parent group (Ascending/Descending) | Descending |

### Default Grouping Behavior

When **"Apply parent grouping by default"** is enabled:
- All issue lists across all projects will automatically group by parent task
- Users can still manually change the grouping if needed
- Saved custom queries are not affected

When disabled:
- Users must manually select "Parent task" from the grouping dropdown

## Usage

### Manual Grouping

1. Navigate to any project's **Issues** page
2. Click on **Options** or the grouping dropdown
3. Select **"Parent task"** from the Group by dropdown
4. Issues will be grouped with headers showing "#ID: Parent Title"

### Group Display Format

**Before (standard Redmine):**
```
123
  - Subtask 1
  - Subtask 2
```

**After (with this plugin):**
```
#123: Implement User Authentication
  - Subtask 1
  - Subtask 2

Estimated time: 40:00  Spent time: 35:00
```

## Technical Details

### How It Works

The plugin uses a custom `ParentIdValue` class that:
- **Displays as formatted string**: Returns `"#123: Parent Task Title"` via `to_s`
- **Acts as integer for aggregation**: Implements `to_i`, `==`, `hash`, `<=>` to behave like the parent_id integer
- **Preserves grouping logic**: Redmine groups by the integer value, ensuring correct time calculations

This dual-nature approach allows the plugin to:
1. Display rich, formatted group labels
2. Maintain accurate aggregation for estimated time, spent time, and subtask counts
3. Preserve proper sorting and comparison operations

### Files Modified

- `lib/parent_grouping/issue_query_patch.rb` - Core functionality
- `app/views/settings/_parent_grouping.html.erb` - Settings interface
- `config/locales/en.yml` - English translations
- `init.rb` - Plugin registration and configuration

## Compatibility

- **Redmine Version**: 6.x
- **Ruby Version**: 3.x
- **Rails Version**: 7.x

## Development

### Running Tests

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:test NAME=parent_grouping
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This plugin is released under the MIT License.

## Author

**Softices**

## Support

For issues, questions, or contributions, please visit:
- GitHub: https://github.com/deven-softices/redmine_group_by_parentID
- Issues: https://github.com/deven-softices/redmine_group_by_parentID/issues

## Changelog

### Version 0.0.1 (2025-12-26)
- Initial release
- Parent task grouping with ID + Title display
- Configurable sort orders
- Optional default grouping
- Correct time aggregation
