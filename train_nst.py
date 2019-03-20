import turicreate as tc

# Load the style and content images
styles = tc.load_images('style/')
content = tc.load_images('content/')

# Create a StyleTransfer model
model = tc.style_transfer.create(styles, content, max_iterations=150)

# Load some test images
test_images = tc.load_images('test/')

# Stylize the test images
stylized_images = model.stylize(test_images)

# Save the model for later use in Turi Create
model.save('DemoNST3.model')

# Export for use in Core ML
model.export_coreml('DemoNST3.mlmodel')
model.export_coreml('DemoNST3.mlmodel', image_shape=(800, 800))


# import turicreate as tc
# 
# 
# loaded_model = tc.load_model('DemoNST_500.model')
# loaded_model.get_styles()
# 
# test_images = tc.load_images('test/')
# stylized_images = loaded_model.stylize(test_images)
# print stylized_images.explore()
# 
# loaded_model.export_coreml('DemoNST2_800x800.mlmodel', image_shape=(800, 800))
