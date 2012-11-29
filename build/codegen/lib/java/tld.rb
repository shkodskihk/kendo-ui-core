module CodeGen::Java
    TYPES = {
        'Number' => 'float',
        'number' => 'float',
        'String' => 'java.lang.String',
        'string' => 'java.lang.String',
        'Boolean' => 'boolean',
        'Object' => 'Object',
        'Array' => 'java.lang.Object',
        'Function' => 'String',
        'Date' => 'java.util.Date'
    }

    IGNORED = {
        'chart' => ['axisDefaults', 'seriesDefaults'],
        'stockchart' => ['axisDefaults', 'seriesDefaults'],
        'window' => ['content.template'],
    }
end

module CodeGen::Java::TLD
    COMPONENT = ERB.new(%{
        <tag>
            <description><%= component.name %></description>
            <name><%= component.name.camelize %></name>
            <tag-class>com.kendoui.taglib.<%= component.name %>Tag</tag-class>
            <body-content>JSP</body-content>
<% if component.name != 'DataSource' %>
            <attribute>
                <description>The mandatory and unique name of the widget. Used as the &quot;id&quot; attribute of the widget HTML element.</description>
                <name>name</name>
                <required>true</required>
                <rtexprvalue>true</rtexprvalue>
                <type>java.lang.String</type>
            </attribute>
<% end %>
            }, 0, '<>%')

    OPTION = ERB.new(%{
            <attribute>
                <description><%= option.description %></description>
                <name><%= option.name.sub(/^[a-z]{1}[A-Z]{1}[a-zA-Z]*/){|c| c.downcase} %></name>
                <rtexprvalue>true</rtexprvalue>
                <type><%= CodeGen::Java::TYPES[option.type] %></type>
            </attribute>
    }, 0, '<>%')

    EVENT = ERB.new(%{
            <attribute>
                <description><%= event.description %></description>
                <name><%= event.name %></name>
                <rtexprvalue>true</rtexprvalue>
            </attribute>
    }, 0, '<>%')
end

class CodeGen::Java::TLD::Generator
    def initialize(filename)
        @filename = filename
        @tld = ''
    end

    def component(component)
        @tld += CodeGen::Java::TLD::COMPONENT.result(binding)

        component.configuration.each do |option|
            next unless option.instance_of? CodeGen::Option

            ignored = CodeGen::Java::IGNORED[component.name.downcase]

            next if ignored && ignored.any? { |ignore| option.name.start_with?(ignore) }

            $stderr.puts "#{option.name} (#{option.type})" if component.name == 'Chart'

            @tld += CodeGen::Java::TLD::OPTION.result(binding)

        end

        component.events.each do |event|

            @tld += CodeGen::Java::TLD::EVENT.result(binding)

        end

        if component.name != 'DataSource'
            @tld += "        <dynamic-attributes>true</dynamic-attributes>\n"
        end

        @tld += '       </tag>'
    end

    def sync()
        src = File.read(@filename)

        src = src.sub(/<!-- Auto-generated -->(.|\n)*<!-- Auto-generated -->/,
                     "<!-- Auto-generated -->\n\n" +
                     @tld +
                     "\n\n<!-- Auto-generated -->")
                 .gsub(/\r?\n/, RUBY_PLATFORM =~ /w32/ ? "\n" : "\r\n")

        File.write(@filename, src)
    end
end
