module Lapis
  abstract class BaseContent
    abstract def title : String
    abstract def content : String
    abstract def url : String
    abstract def date : Time?
    abstract def tags : Array(String)
    abstract def categories : Array(String)
    abstract def description : String?
    abstract def excerpt(length : Int32 = 200) : String
  end
end
