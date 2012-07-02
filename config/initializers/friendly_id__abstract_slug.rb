# This initializer needs to run after any other initializers that touch the slug model.

AbstractSlug = Slug
AbstractSlug.abstract_class = true
Object.send :remove_const, :Slug