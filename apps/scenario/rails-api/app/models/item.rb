# The benchmark's single-row read resource. The table is created and seeded
# by the image build, so the model declares only its table and relies on the
# schema.
class Item < ApplicationRecord
  self.table_name = "items"
end
