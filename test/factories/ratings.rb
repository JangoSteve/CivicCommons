# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :rating do |f|
  f.association :person, :factory => :normal_person
  f.association :contribution, :factory => :comment
  f.association :rating_descriptor, :factory => :rating_descriptor
end
