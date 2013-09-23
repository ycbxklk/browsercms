# Returns a file upload input tag for a given block, along with label and instructions.
#
# @param [Symbol] method The name of the model this form upload is associated with
# @param [Hash] options
# @option options [String] :label (method) If no label is specified, the human readable name for method will be used.
# @option options [String] :hint (blank) Helpful tips for the person entering the field, appears blank if nothing is specified.
class FilePickerInput < SimpleForm::Inputs::Base

  def input
    # New blocks will not have their attachments created yet.
    object.ensure_attachment_exists if object.respond_to?(:ensure_attachment_exists)

    html = ""
    if render_section_picker?
      sections = sections_with_full_paths
      sections.each do |s|
        html << template.tag(:span, :class => "section_id_map", style: 'display: hidden', :data => {:id => s.id, :path => s.prependable_path})
      end
    end
    @builder.simple_fields_for :attachments do |a|
      if matching_attachment?(a)
        html << a.hidden_field("attachment_name", value: attribute_name.to_s)
        html << a.file_field(:data, input_html_options.merge('data-purpose' => "cms_file_field"))
        if render_section_picker?
          html << a.input(:section_id, collection: sections, label_method: :full_path, include_blank: false, label: "Section", input_html: {'data-purpose' => "section_selector"})
        end
        if render_path_input?
          klass = object.new_record? ? "suggest_file_path" : "keep_existing_path"
          html << a.input(:data_file_path, label: "Path", input_html: {class: klass})
        end
      end
    end
    html.html_safe

  end

  # Because #attachments holds ALL attachments by all names, need to verify we only render one form control for each one.
  def matching_attachment?(a)
    a.object.attachment_name == attribute_name.to_s
  end

  def render_path_input?
    object.respond_to?(:set_attachment_path)
  end

  def render_section_picker?
    object.respond_to?(:set_attachment_section)
  end


  def sections_with_full_paths
    root = Cms::Section.root.first
    root.full_path = root.name
    sections = []
    sections << root
    sections += root.master_section_list
    sections.each { |s| s.full_path = "/" + s.full_path unless s == root }
    sections
  end

end