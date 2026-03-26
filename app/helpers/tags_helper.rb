module TagsHelper
  def tag_variant_class(variant)
    case variant.to_s
    when "atelier"
      "bg-terracotta text-white"
    when "stage"
      "bg-terracotta-light text-white"
    when "gratuit"
      "bg-green-100 text-green-800"
    when "en_ligne"
      "bg-blue-100 text-blue-800"
    when "en_presentiel"
      "bg-gray-200 text-gray-800"
    else
      "bg-gray-100 text-gray-700"
    end
  end
end
