class WestacoVersionsHook < Redmine::Hook::ViewListener

    def view_layouts_base_html_head(context = {})
        stylesheets = stylesheet_link_tag('versions', :plugin => 'westaco_versions')
        if File.exist?(File.join(File.dirname(__FILE__), "../assets/stylesheets/#{Setting.ui_theme}.css"))
            stylesheets << stylesheet_link_tag(Setting.ui_theme, :plugin => 'westaco_versions')
        end
        stylesheets
    end

end
