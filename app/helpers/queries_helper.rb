# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2016  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module QueriesHelper
  include ApplicationHelper

  def filters_options_for_select(query)
    ungrouped = []
    grouped = {}
    query.available_filters.map do |field, field_options|
      if field_options[:type] == :relation
        group = :label_relations
      elsif field_options[:type] == :tree
        group = query.is_a?(IssueQuery) ? :label_relations : nil
      elsif field =~ /^(.+)\./
        # association filters
        group = "field_#{$1}"
      elsif %w(member_of_group assigned_to_role).include?(field)
        group = :field_assigned_to
      elsif field_options[:type] == :date_past || field_options[:type] == :date
        group = :label_date
      end
      if group
        (grouped[group] ||= []) << [field_options[:name], field]
      else
        ungrouped << [field_options[:name], field]
      end
    end
    # Don't group dates if there's only one (eg. time entries filters)
    if grouped[:label_date].try(:size) == 1 
      ungrouped << grouped.delete(:label_date).first
    end
    s = options_for_select([[]] + ungrouped)
    if grouped.present?
      localized_grouped = grouped.map {|k,v| [l(k), v]}
      s << grouped_options_for_select(localized_grouped)
    end
    s
  end

  def query_filters_hidden_tags(query)
    tags = ''.html_safe
    query.filters.each do |field, options|
      tags << hidden_field_tag("f[]", field, :id => nil)
      tags << hidden_field_tag("op[#{field}]", options[:operator], :id => nil)
      options[:values].each do |value|
        tags << hidden_field_tag("v[#{field}][]", value, :id => nil)
      end
    end
    tags
  end

  def query_columns_hidden_tags(query)
    tags = ''.html_safe
    query.columns.each do |column|
      tags << hidden_field_tag("c[]", column.name, :id => nil)
    end
    tags
  end

  def query_hidden_tags(query)
    query_filters_hidden_tags(query) + query_columns_hidden_tags(query)
  end

  def group_by_column_select_tag(query)
    options = [[]] + query.groupable_columns.collect {|c| [c.caption, c.name.to_s]}
    select_tag('group_by', options_for_select(options, @query.group_by))
  end

  def available_block_columns_tags(query)
    tags = ''.html_safe
    query.available_block_columns.each do |column|
      tags << content_tag('label', check_box_tag('c[]', column.name.to_s, query.has_column?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags
  end

  def available_totalable_columns_tags(query)
    tags = ''.html_safe
    query.available_totalable_columns.each do |column|
      tags << content_tag('label', check_box_tag('t[]', column.name.to_s, query.totalable_columns.include?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags << hidden_field_tag('t[]', '')
    tags
  end

  def query_available_inline_columns_options(query)
    (query.available_inline_columns - query.columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
  end

  def query_selected_inline_columns_options(query)
    (query.inline_columns & query.available_inline_columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
  end

  def render_query_columns_selection(query, options={})
    tag_name = (options[:name] || 'c') + '[]'
    render :partial => 'queries/columns', :locals => {:query => query, :tag_name => tag_name}
  end

  def grouped_query_results(items, query, item_count_by_group, &block)
    previous_group, first = false, true
    totals_by_group = query.totalable_columns.inject({}) do |h, column|
      h[column] = query.total_by_group_for(column)
      h
    end
    items.each do |item|
      group_name = group_count = nil
      if query.grouped?
        group = query.group_by_column.value(item)
        if first || group != previous_group
          if group.blank? && group != false
            group_name = "(#{l(:label_blank_value)})"
          else
            group_name = format_object(group)
          end
          group_name ||= ""
          group_count = item_count_by_group ? item_count_by_group[group] : nil
          group_totals = totals_by_group.map {|column, t| total_tag(column, t[group] || 0)}.join(" ").html_safe
        end
      end
      yield item, group_name, group_count, group_totals
      previous_group, first = group, false
    end
  end

  def render_query_totals(query)
    return unless query.totalable_columns.present?
    totals = query.totalable_columns.map do |column|
      total_tag(column, query.total_for(column))
    end
    content_tag('p', totals.join(" ").html_safe, :class => "query-totals")
  end

  def total_tag(column, value)
    label = content_tag('span', "#{column.caption}:")
    value = content_tag('span', format_object(value), :class => 'value')
    content_tag('span', label + " " + value, :class => "total-for-#{column.name.to_s.dasherize}")
  end

  def column_header(column)
    column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                                        :default_order => column.default_order) :
                      content_tag('th', h(column.caption))
  end

  def column_content(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value(column, issue, value)
    end
  end
  
  def column_value(column, issue, value)
    case column.name
    when :id
      link_to value, issue_path(issue)
    when :subject
      link_to value, issue_path(issue)
    when :parent
      value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
    when :description
      issue.description? ? content_tag('div', textilizable(issue, :description), :class => "wiki") : ''
    when :done_ratio
      progress_bar(value)
    when :relations
      content_tag('span',
        value.to_s(issue) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
        :class => value.css_classes_for(issue))
    else
      format_object(value)
    end
  end

  def csv_content(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| csv_value(column, issue, v)}.compact.join(', ')
    else
      csv_value(column, issue, value)
    end
  end

  def csv_value(column, object, value)
    format_object(value, false) do |value|
      case value.class.name
      when 'Float'
        sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
      when 'IssueRelation'
        value.to_s(object)
      when 'Issue'
        if object.is_a?(TimeEntry)
          "#{value.tracker} ##{value.id}: #{value.subject}"
        else
          value.id
        end
      else
        value
      end
    end
  end

  def query_to_csv(items, query, options={})
    options ||= {}
    columns = (options[:columns] == 'all' ? query.available_inline_columns : query.inline_columns)
    query.available_block_columns.each do |column|
      if options[column.name].present?
        columns << column
      end
    end

    Redmine::Export::CSV.generate do |csv|
      # csv header fields
      csv << columns.map {|c| c.caption.to_s}
      # csv lines
      items.each do |item|
        csv << columns.map {|c| csv_content(c, item)}
      end
    end
  end

  # Retrieve query from session or build a new query
  def retrieve_query(klass=IssueQuery, use_session=true)
    session_key = klass.name.underscore.to_sym

    if params[:query_id].present?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = klass.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[session_key] = {:id => @query.id, :project_id => @query.project_id} if use_session
      sort_clear
    elsif api_request? || params[:set_filter] || !use_session || session[session_key].nil? || session[session_key][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = klass.new(:name => "_", :project => @project)
      @query.build_from_params(params)
      session[session_key] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :totalable_names => @query.totalable_names} if use_session
    else
      # retrieve from session
      @query = nil
      @query = klass.find_by_id(session[session_key][:id]) if session[session_key][:id]
      @query ||= klass.new(:name => "_", :filters => session[session_key][:filters], :group_by => session[session_key][:group_by], :column_names => session[session_key][:column_names], :totalable_names => session[session_key][:totalable_names])
      @query.project = @project
    end
  end

  def retrieve_query_from_session
    if session[:query]
      if session[:query][:id]
        @query = IssueQuery.find_by_id(session[:query][:id])
        return unless @query
      else
        @query = IssueQuery.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names], :totalable_names => session[:query][:totalable_names])
      end
      if session[:query].has_key?(:project_id)
        @query.project_id = session[:query][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  # Returns the query definition as hidden field tags
  def query_as_hidden_field_tags(query)
    tags = hidden_field_tag("set_filter", "1", :id => nil)

    if query.filters.present?
      query.filters.each do |field, filter|
        tags << hidden_field_tag("f[]", field, :id => nil)
        tags << hidden_field_tag("op[#{field}]", filter[:operator], :id => nil)
        filter[:values].each do |value|
          tags << hidden_field_tag("v[#{field}][]", value, :id => nil)
        end
      end
    else
      tags << hidden_field_tag("f[]", "", :id => nil)
    end
    if query.column_names.present?
      query.column_names.each do |name|
        tags << hidden_field_tag("c[]", name, :id => nil)
      end
    end
    if query.totalable_names.present?
      query.totalable_names.each do |name|
        tags << hidden_field_tag("t[]", name, :id => nil)
      end
    end
    if query.group_by.present?
      tags << hidden_field_tag("group_by", query.group_by, :id => nil)
    end

    tags
  end

  # Returns the queries that are rendered in the sidebar
  def sidebar_queries(klass, project)
    klass.visible.global_or_on_project(@project).sorted.to_a
  end

  # Renders a group of queries
  def query_links(title, queries)
    return '' if queries.empty?
    # links to #index on issues/show
    url_params = controller_name == 'issues' ? {:controller => 'issues', :action => 'index', :project_id => @project} : {}

    content_tag('h3', title) + "\n" +
      content_tag('ul',
        queries.collect {|query|
            css = 'query'
            css << ' selected' if query == @query
            content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
          }.join("\n").html_safe,
        :class => 'queries'
      ) + "\n"
  end

  # Renders the list of queries for the sidebar
  def render_sidebar_queries(klass, project)
    queries = sidebar_queries(klass, project)

    out = ''.html_safe
    out << query_links(l(:label_my_queries), queries.select(&:is_private?))
    out << query_links(l(:label_query_plural), queries.reject(&:is_private?))
    out
  end
end