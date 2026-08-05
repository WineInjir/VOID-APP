from kivymd.app import MDApp
from kivymd.uix.screen import MDScreen

class MainApp(MDApp):
    def build(self):
        self.theme_cls.theme_style = "Light"
        self.theme_cls.primary_palette = "Indigo"
        return MDScreen()

    def on_button_press(self):
        self.root.ids.label.text = "Кнопка нажата!"


if __name__ == "__main__":
    MainApp().run()