module Babelphish
  module HtmlTranslator

    class << self
      
      # Translates all files in the given path from the language 
      # specififed by 'translate_from' into the languages in 'translate_tos'.
      # Translations that already exist will not be overwritten unless overwrite = true
      def translate(path, translate_tos, translate_from = 'en', overwrite = false)
        @path = path
        if !Babelphish::GoogleTranslate::LANGUAGES.include?(translate_from)
          STDERR.puts "#{translate_from} is not one of the available languages."
          return
        end
        if !File.exists?(path)
          STDERR.puts "#{path} does not exist."
          return
        end
        translate_and_write_pages(path, translate_tos, translate_from, overwrite)        
      end

      def translate_and_write_pages(path, tos, from, overwrite)
        Dir.glob("#{path}/*").each do |next_file|
          if File.directory?(next_file)
            translate_and_write_pages(next_file, language)
          else
            translate_and_write_page(next_file, tos, from, overwrite)
          end
        end
      end

      # Translate a single page from the language specified in 'from'
      # into the languages specified by 'tos'
      def translate_and_write_page(source_page, tos, from, overwrite)
        return unless File.exist?(source_page)
        return unless translate_file?(source_page)
        text = IO.read(source_page)
        
        # Pull out all the code blocks to Google doesn't mess with those
        pattern = /\<\%.+\%\>/
        holder = '{{---}}'
        replacements = text.scan(pattern)
        text.gsub!(pattern, holder)
        
        # Send to Google for translations
        translations = Babelphish::Translator.multiple_translate(text, tos, from)
        
        # Put the code back
        translations.each_key do |locale|
          replacements.each do |r|
            translations[locale].sub!(holder, r)
          end
        end

        # Write the new file
        translations.each_key do |locale|
          translated_filename = get_translated_file(source_page, locale)
          if (locale != from) && (overwrite || !File.exists?(translated_filename))
            File.open(translated_filename, 'w') { |f| f.write(translations[locale]) }
          end
        end

      end

      def get_translated_file(page, to)
        page.gsub('.html', ".#{to}.html")
      end
      
      def translate_file?(page)
        page.split('.').length == 3
      end
      
    end
  end
end