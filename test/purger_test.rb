require "test_helper"

class Tailwindcss::PurgerTest < ActiveSupport::TestCase
  test "extract class names from string" do
    assert_equal %w[ div class max-w-7xl mx-auto my-1.5 px-4 sm:px-6 lg:px-8 sm:py-0.5 translate-x-1/2 ].sort,
      Tailwindcss::Purger.extract_class_names(%(<div class="max-w-7xl mx-auto my-1.5 px-4 sm:px-6 lg:px-8 sm:py-0.5 translate-x-1/2">))
  end

  test "extract class names from files" do
    assert_equal %w[ div class max-w-7xl mx-auto my-1.5 px-4 sm:px-6 lg:px-8 sm:py-0.5 translate-x-1/2 ].sort,
      Tailwindcss::Purger.extract_class_names_from(Pathname.new(__dir__).join("fixtures/simple.html.erb"))
  end

  test "basic purge" do
    purged = purged_tailwind_from_fixtures

    assert purged !~ /.mt-6 \{/

    assert purged =~ /.mt-5 \{/
    assert purged =~ /.sm\\:px-6 \{/
    assert purged =~ /.translate-x-1\\\/2 \{/
    assert purged =~ /.mt-10 \{/
    assert purged =~ /.my-1\\.5 \{/
    assert purged =~ /.sm\\:py-0\\.5 \{/
  end

  test "purge handles compound selectors" do
    purged = purged_tailwind_from_fixtures

    assert purged !~ /.group-hover\\:text-gray-100/

    assert purged =~ /.group:hover .group-hover\\:text-gray-500 \{/
  end

  test "purge removes selectors that aren't on the same line as their block brace" do
    purged = purged_tailwind_from_fixtures

    assert purged !~ /.aspect-w-1,/
    assert purged !~ /,\s*@media/

    assert purged =~ /.aspect-w-9[, ]/
  end

  test "purge removes empty blocks" do
    purged = purged_tailwind_from_fixtures
    assert purged !~ /\{\s*\}/
  end

  test "purge shouldn't remove hover or focus classes" do
    purged = purged_tailwind_from_fixtures
    assert purged =~ /.hover\\\:text-gray-500\:hover \{/
    assert purged =~ /.focus\\\:outline-none\:focus \{/
    assert purged =~ /.focus-within\\\:outline-black\:focus-within \{/
  end

  test "purge shouldn't remove placeholder selectors" do
    purged = purged_tailwind_from Pathname(__dir__).join("fixtures/placeholders.html.erb")

    assert purged =~ /.placeholder-transparent\:\:-moz-placeholder \{/
    assert purged =~ /.placeholder-transparent\:-ms-input-placeholder \{/
    assert purged =~ /.placeholder-transparent\:\:placeholder \{/
  end

  private
    def purged_tailwind_from_fixtures
      $purged_tailwind_from_fixtures ||= purged_tailwind_from Pathname(__dir__).glob("fixtures/*.html.erb")
    end

    def purged_tailwind_from files
      Tailwindcss::Purger.purge \
        Pathname.new(__FILE__).join("../../app/assets/stylesheets/tailwind.css").read,
        keeping_class_names_from_files: files
    end
end
